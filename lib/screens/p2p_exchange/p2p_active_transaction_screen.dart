import 'dart:io';

import 'package:afercon_pay/models/p2p_transaction_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/p2p_exchange/dispute_chat_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/p2p_exchange_service.dart';
import 'package:afercon_pay/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class P2PActiveTransactionScreen extends StatefulWidget {
  final String transactionId;

  const P2PActiveTransactionScreen({super.key, required this.transactionId});

  @override
  State<P2PActiveTransactionScreen> createState() =>
      _P2PActiveTransactionScreenState();
}

class _P2PActiveTransactionScreenState
    extends State<P2PActiveTransactionScreen> {
  final P2PExchangeService _exchangeService = P2PExchangeService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  late Stream<P2PTransaction> _transactionStream;
  String? _currentUserId;
  File? _proofImageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _transactionStream =
        _exchangeService.getTransactionStream(widget.transactionId);
    _loadInitialData();
  }

  void _loadInitialData() {
    final user = _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?.uid;
      });
    }
  }

  Future<void> _selectProofImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _proofImageFile = File(image.path);
      });
    }
  }

  Future<void> _confirmPaymentSent() async {
    if (_proofImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, anexe o comprovativo.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final proofUrl = await _storageService.uploadPaymentProof(
          _proofImageFile!, widget.transactionId);
      await _exchangeService.updateTransactionStatus(
        widget.transactionId,
        P2PTransactionStatus.paymentSent,
        paymentProofUrl: proofUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _confirmPaymentReceived() {
    return _exchangeService.updateTransactionStatus(
      widget.transactionId,
      P2PTransactionStatus.paymentConfirmed,
    );
  }

  Future<void> _openDispute() async {
    final bool confirmDispute = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Abrir Disputa'),
            content: const Text(
                'Tem a certeza que quer abrir uma disputa para esta transação? Esta ação não pode ser revertida.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Abrir Disputa',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDispute) {
      try {
        await _exchangeService.updateTransactionStatus(
          widget.transactionId,
          P2PTransactionStatus.disputed,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao abrir disputa: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Transação')),
      body: StreamBuilder<P2PTransaction>(
        stream: _transactionStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _currentUserId == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar a transação.'));
          }

          final transaction = snapshot.data!;
          final bool isBuyer = transaction.buyerId == _currentUserId;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContentForStatus(transaction, isBuyer),
          );
        },
      ),
    );
  }

  Widget _buildContentForStatus(P2PTransaction transaction, bool isBuyer) {
    switch (transaction.status) {
      case P2PTransactionStatus.awaitingPayment:
        return isBuyer
            ? _buildAwaitingPaymentView(transaction)
            : const Center(
                child: Text(
                    'A aguardar que o comprador efetue o pagamento.'));

      case P2PTransactionStatus.paymentSent:
        return isBuyer
            ? _buildPaymentSentViewAsBuyer(transaction)
            : _buildPaymentSentViewAsSeller(transaction, isBuyer);

      case P2PTransactionStatus.paymentConfirmed:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text('Transação concluída com sucesso!')
            ],
          ),
        );

      case P2PTransactionStatus.cancelled:
        return Center(child: Text('Transação ${transaction.status.name}'));

      case P2PTransactionStatus.disputed:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              const Text('Esta transação está em disputa.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DisputeChatScreen(transactionId: transaction.id),
                  ));
                },
                child: const Text('Ir para a Disputa'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildAwaitingPaymentView(P2PTransaction transaction) {
    return FutureBuilder<UserModel?>(
        future: _firestoreService.getUser(transaction.sellerId),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final seller = userSnapshot.data!;
          final paymentDetail = seller.paymentDetails.isNotEmpty
              ? seller.paymentDetails.first
              : PaymentDetail(
                  method: 'N/A', details: 'Detalhes de pagamento não encontrados.');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aguardando seu Pagamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                  child: ListTile(
                      title: Text(seller.displayName ?? 'Nome Indisponível'),
                      subtitle: Text(paymentDetail.details))),
              const SizedBox(height: 16),
              Text(
                  'Valor a pagar: ${transaction.amountAOA.toStringAsFixed(2)} AOA'),
              const SizedBox(height: 20),
              _proofImageFile != null
                  ? Image.file(_proofImageFile!, height: 150)
                  : const Text('Nenhum comprovativo anexado.'),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Anexar Comprovativo'),
                  onPressed: _selectProofImage,
                ),
              ),
              const Spacer(),
              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmPaymentSent,
                    child: const Text('Já Paguei'),
                  ),
                ),
            ],
          );
        });
  }

  Widget _buildPaymentSentViewAsBuyer(P2PTransaction transaction) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Aguardando Confirmação do Vendedor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text(
            'O seu comprovativo foi enviado. O vendedor foi notificado para confirmar o recebimento do pagamento.'),
        if (transaction.paymentProofUrl != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(transaction.paymentProofUrl!),
          ),
        const Spacer(),
      ],
    );
  }

  Widget _buildPaymentSentViewAsSeller(
      P2PTransaction transaction, bool isBuyer) {
    final amountToReceive =
        isBuyer ? transaction.amountOtherCurrency : transaction.amountAOA;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('O Comprador Marcou como Pago',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
            'Por favor, confirme se recebeu o pagamento no valor de ${amountToReceive.toStringAsFixed(2)} na sua conta.'),
        if (transaction.paymentProofUrl != null)
          Expanded(
              child: InteractiveViewer(
                  child: Image.network(transaction.paymentProofUrl!)))
        else
          const Text('O comprador não enviou um comprovativo.'),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmPaymentReceived,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmo que Recebi o Pagamento'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _openDispute,
            child: const Text('Abrir Disputa',
                style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
