import 'package:afercon_pay/models/exchange_offer_model.dart';
import 'package:afercon_pay/models/p2p_transaction_model.dart';
import 'package:afercon_pay/screens/p2p_exchange/p2p_active_transaction_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/p2p_exchange_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class P2PTransactionScreen extends StatefulWidget {
  final ExchangeOffer offer;

  const P2PTransactionScreen({super.key, required this.offer});

  @override
  State<P2PTransactionScreen> createState() => _P2PTransactionScreenState();
}

class _P2PTransactionScreenState extends State<P2PTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exchangeService = P2PExchangeService();
  final _authService = AuthService(); // Adicionar auth service
  final _amountController = TextEditingController();

  double _amountToPay = 0.0;
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    if(mounted) setState(() => _currentUserId = user?.uid);
  }

  void _calculateAmountToPay(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    // A lógica de cálculo depende do tipo de oferta.
    // Se for uma oferta de VENDA, eu (comprador) pago o valor * a taxa.
    // Se for uma oferta de COMPRA, eu (vendedor) recebo o valor / a taxa (não aplicável aqui)
    if (widget.offer.type == OfferType.sell) {
      setState(() {
        _amountToPay = amount * widget.offer.rate;
      });
    } else {
      // Lógica para quando o utilizador está a VENDER para uma oferta de COMPRA
      setState(() {
         _amountToPay = amount / widget.offer.rate; // Exemplo
      });
    }
  }

  Future<void> _startTransaction() async {
    if (_currentUserId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilizador não autenticado!')));
       return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final double amountInFromCurrency = double.parse(_amountController.text);

      final transaction = P2PTransaction(
        id: '', // Será gerado pelo Firestore
        offerId: widget.offer.id,
        sellerId: widget.offer.offererId, // O criador da oferta é o vendedor
        buyerId: _currentUserId!, // O utilizador atual é o comprador
        amountAOA: _amountToPay, // O valor a ser pago em AOA
        amountOtherCurrency: amountInFromCurrency, // O valor a ser recebido na outra moeda
        exchangeRate: widget.offer.rate,
        status: P2PTransactionStatus.awaitingPayment,
        createdAt: Timestamp.now(),
        // paymentProofUrl é nulo no início
      );

      try {
        final transactionId = await _exchangeService.createTransaction(transaction);

        if (mounted) {
          // Navega para o ecrã de transação ativa, substituindo o ecrã atual
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => P2PActiveTransactionScreen(transactionId: transactionId),
          ));
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao iniciar transação: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comprar ${widget.offer.fromCurrency}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendedor: ${widget.offer.offererName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Taxa: 1 ${widget.offer.fromCurrency} = ${widget.offer.rate} ${widget.offer.toCurrency}'),
              Text('Disponível: ${widget.offer.availableAmount} ${widget.offer.fromCurrency}'),
              Text('Limites: ${widget.offer.minLimit} - ${widget.offer.maxLimit} ${widget.offer.fromCurrency}'),
              Text('Pagamento: ${widget.offer.paymentMethods.join(', ')}'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                onChanged: _calculateAmountToPay,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quanto você quer comprar (${widget.offer.fromCurrency})',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obrigatório';
                  final amount = double.tryParse(value);
                  if (amount == null) return 'Valor inválido';
                  if (amount < widget.offer.minLimit) return 'Valor abaixo do limite mínimo';
                  if (amount > widget.offer.maxLimit) return 'Valor acima do limite máximo';
                  if (amount > widget.offer.availableAmount) return 'Valor acima do disponível';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_amountToPay > 0)
                Text(
                  'Você pagará: ${_amountToPay.toStringAsFixed(2)} ${widget.offer.toCurrency}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startTransaction,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text('Iniciar Compra Segura'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
