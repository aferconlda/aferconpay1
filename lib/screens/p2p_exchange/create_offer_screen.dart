import 'package:afercon_pay/models/exchange_offer_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/currency_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/p2p_exchange_service.dart';
import 'package:afercon_pay/services/payment_methods_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exchangeService = P2PExchangeService();
  final _paymentMethodsService = PaymentMethodsService();
  final _currencyService = CurrencyService();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _rateController = TextEditingController();
  final _amountController = TextEditingController();
  final _minLimitController = TextEditingController();
  final _maxLimitController = TextEditingController();

  OfferType _offerType = OfferType.sell;
  String? _fromCurrency;
  String? _toCurrency;
  Map<String, bool> _paymentMethods = {};
  List<String> _selectedPaymentMethods = [];

  bool _isSubmitting = false;
  bool _isLoadingInitialData = true;

  List<String> _sellableCurrencies = [];
  List<String> _buyableCurrencies = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final authUser = _authService.getCurrentUser();
      if (authUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilizador não autenticado.')),
          );
          setState(() => _isLoadingInitialData = false);
        }
        return;
      }

      final methodsFuture = _paymentMethodsService.getAvailablePaymentMethods();
      final sellableFuture = _currencyService.getSellableCurrencies();
      final buyableFuture = _currencyService.getBuyableCurrencies();
      final userModelFuture = _firestoreService.getUser(authUser.uid);

      final results = await Future.wait([
        methodsFuture,
        sellableFuture,
        buyableFuture,
        userModelFuture,
      ]);

      if (mounted) {
        setState(() {
          _paymentMethods = {for (var method in results[0] as List<String>) method: false};
          _sellableCurrencies = results[1] as List<String>;
          _buyableCurrencies = results[2] as List<String>;
          _currentUser = results[3] as UserModel?;
          _setInitialCurrencies();
          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados iniciais: $e')),
        );
        setState(() {
          _isLoadingInitialData = false;
        });
      }
    }
  }

  void _setInitialCurrencies() {
    if (_offerType == OfferType.sell) {
      _fromCurrency = _sellableCurrencies.isNotEmpty ? _sellableCurrencies.first : null;
      _toCurrency = _buyableCurrencies.isNotEmpty ? _buyableCurrencies.first : null;
    } else {
      _fromCurrency = _buyableCurrencies.isNotEmpty ? _buyableCurrencies.first : null;
      _toCurrency = _sellableCurrencies.isNotEmpty ? _sellableCurrencies.first : null;
    }
  }

  Future<void> _submitOffer() async {
    _selectedPaymentMethods = _paymentMethods.entries.where((e) => e.value).map((e) => e.key).toList();

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPaymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione pelo menos um método de pagamento.')));
      return;
    }
    if (_fromCurrency == null || _toCurrency == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione as moedas da oferta.')));
      return;
    }
    if (_currentUser == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilizador não autenticado.')));
      return;
    }

    setState(() => _isSubmitting = true);

    final offer = ExchangeOffer(
      id: '',
      offererId: _currentUser!.uid,
      offererName: _currentUser!.displayName ?? 'Nome Indisponível',
      type: _offerType,
      fromCurrency: _fromCurrency!,
      toCurrency: _toCurrency!,
      rate: double.parse(_rateController.text),
      availableAmount: double.parse(_amountController.text),
      minLimit: double.parse(_minLimitController.text),
      maxLimit: double.parse(_maxLimitController.text),
      paymentMethods: _selectedPaymentMethods,
      status: OfferStatus.open,
      createdAt: Timestamp.now(),
    );

    try {
      await _exchangeService.createOffer(offer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta criada com sucesso!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar oferta: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Nova Oferta')),
      body: _isLoadingInitialData
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfferTypeToggle(),
            const SizedBox(height: 20),
            _buildCurrencyDropdowns(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Sua taxa de câmbio'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Insira uma taxa válida' : null,
            ),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Quantidade total a ${_offerType == OfferType.sell ? 'vender' : 'comprar'}'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Insira uma quantidade válida' : null,
            ),
            TextFormField(
              controller: _minLimitController,
              decoration: const InputDecoration(labelText: 'Limite mínimo por transação'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Insira um limite válido' : null,
            ),
            TextFormField(
              controller: _maxLimitController,
              decoration: const InputDecoration(labelText: 'Limite máximo por transação'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Insira um limite válido' : null,
            ),
            const SizedBox(height: 20),
            const Text('Métodos de Pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_paymentMethods.isEmpty)
              const Padding(padding: EdgeInsets.all(8.0), child: Text('Nenhum método de pagamento disponível.'))
            else
              ..._paymentMethods.keys.map((method) => CheckboxListTile(
                title: Text(method),
                value: _paymentMethods[method],
                onChanged: _isSubmitting ? null : (bool? value) => setState(() => _paymentMethods[method] = value!),
              )),
            const SizedBox(height: 20),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitOffer,
                  child: const Text('Publicar Oferta'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOfferTypeToggle() {
    return SegmentedButton<OfferType>(
      segments: const <ButtonSegment<OfferType>>[
        ButtonSegment<OfferType>(value: OfferType.sell, label: Text('Quero Vender')),
        ButtonSegment<OfferType>(value: OfferType.buy, label: Text('Quero Comprar')),
      ],
      selected: <OfferType>{_offerType},
      onSelectionChanged: (Set<OfferType> newSelection) {
        setState(() {
          _offerType = newSelection.first;
          // Inverte as moedas ao trocar o tipo de oferta
          final temp = _fromCurrency;
          _fromCurrency = _toCurrency;
          _toCurrency = temp;
        });
      },
    );
  }

  Widget _buildCurrencyDropdowns() {
    final List<String> fromCurrencies = _offerType == OfferType.sell ? _sellableCurrencies : _buyableCurrencies;
    final List<String> toCurrencies = _offerType == OfferType.sell ? _buyableCurrencies : _sellableCurrencies;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: fromCurrencies.contains(_fromCurrency) ? _fromCurrency : null,
            hint: Text(_offerType == OfferType.sell ? 'Vender' : 'Comprar'),
            items: fromCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: _isSubmitting ? null : (value) => setState(() => _fromCurrency = value),
            validator: (v) => (v == null) ? 'Obrigatório' : null,
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_forward),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: toCurrencies.contains(_toCurrency) ? _toCurrency : null,
            hint: Text(_offerType == OfferType.sell ? 'Receber' : 'Pagar com'),
            items: toCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: _isSubmitting ? null : (value) => setState(() => _toCurrency = value),
            validator: (v) => (v == null) ? 'Obrigatório' : null,
          ),
        ),
      ],
    );
  }
}
