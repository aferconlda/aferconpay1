import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/functions_service.dart';
import 'package:afercon_pay/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CashierWithdrawalScreen extends StatefulWidget {
  const CashierWithdrawalScreen({super.key});

  @override
  State<CashierWithdrawalScreen> createState() =>
      _CashierWithdrawalScreenState();
}

class _CashierWithdrawalScreenState extends State<CashierWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  // Serviços
  final _firestoreService = FirestoreService();
  final _functionsService = FunctionsService();
  final _pinService = PinService();

  // Controladores
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  // Estado
  UserModel? _foundClient;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _searchError;

  // Estado para cálculo de taxas
  double _transactionFee = 0.0;
  double _totalDebited = 0.0;
  static const double _feeRate = 0.045; // Taxa de 4.5%
  final _currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateFeeCalculation);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.removeListener(_updateFeeCalculation);
    _amountController.dispose();
    super.dispose();
  }

  void _updateFeeCalculation() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _transactionFee = amount * _feeRate;
      _totalDebited = amount + _transactionFee;
    });
  }

  Future<void> _findClientByPhone() async {
    if (_phoneController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundClient = null;
      _searchError = null;
    });

    try {
      final client = await _firestoreService.findUserByPhone(_phoneController.text.trim());
      if (!mounted) return;
      if (client == null) {
        setState(() =>
            _searchError = 'Nenhum cliente encontrado com este número.');
      } else {
        setState(() => _foundClient = client);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchError = 'Ocorreu um erro ao procurar o cliente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _processWithdrawal() async {
    if (!(_formKey.currentState?.validate() ?? false) || _foundClient == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final messenger = ScaffoldMessenger.of(context);

    final pinConfirmed = await _showPinConfirmationDialog();
    if (!mounted) return;

    if (pinConfirmed != true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN inválido ou operação cancelada.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final result = await _functionsService.processQrTransaction(
      context: context,
      data: {
        'clientUid': _foundClient!.uid,
        'amount': amount,
        'transactionType': 'withdrawal',
      },
    );

    if (mounted) {
      if (result != null) {
        _formKey.currentState?.reset();
        _phoneController.clear();
        _amountController.clear();
        setState(() {
          _foundClient = null;
          _searchError = null;
        });
      }
       setState(() => _isProcessing = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Processar Levantamento do Cliente')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchCard(theme),
              if (_searchError != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(_searchError!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              SizedBox(height: 24.h),
              if (_foundClient != null) _buildWithdrawalForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1. Encontrar o Cliente', style: theme.textTheme.titleLarge),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
              labelText: 'Nº de Telemóvel do Cliente',
              prefixIcon: Icon(Icons.phone)),
          keyboardType: TextInputType.phone,
          validator: (value) =>
              (value?.isEmpty ?? true) ? 'Insira um número.' : null,
        ),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _isSearching ? null : _findClientByPhone,
          icon: _isSearching
              ? const SizedBox.shrink()
              : const Icon(Icons.search),
          label: _isSearching
              ? const CircularProgressIndicator()
              : const Text('Procurar Cliente'),
        ),
      ],
    );
  }

  Widget _buildWithdrawalForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('2. Confirmar Detalhes', style: theme.textTheme.titleLarge),
        SizedBox(height: 16.h),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.orange, size: 40),
            title: Text(_foundClient!.displayName ?? 'Nome não disponível', style: theme.textTheme.titleMedium),
            subtitle: Text(
                'Saldo atual: ${_currencyFormat.format(_foundClient!.balance)}'),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
              labelText: 'Valor a Entregar ao Cliente (Kz)',
              prefixIcon: Icon(Icons.attach_money)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Insira um valor.';
            final amount = double.tryParse(value) ?? 0;
            if (amount <= 0) return 'O valor deve ser positivo.';
            if (_foundClient != null && _foundClient!.balance < _totalDebited) {
              return 'Saldo insuficiente. O cliente precisa de ${_currencyFormat.format(_totalDebited)}.';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        if (_amountController.text.isNotEmpty && (double.tryParse(_amountController.text) ?? 0) > 0)
          _buildFeeSummaryCard(theme),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processWithdrawal,
          style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              backgroundColor: Colors.orange),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('CONFIRMAR LEVANTAMENTO'),
        ),
      ],
    );
  }

  Widget _buildFeeSummaryCard(ThemeData theme) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo da Transação', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            _buildSummaryRow('Valor a Entregar:', _currencyFormat.format(amount)),
            const Divider(),
            _buildSummaryRow('Taxa de Serviço (4.5%):', '+ ${_currencyFormat.format(_transactionFee)}'),
            const Divider(),
            _buildSummaryRow('Total Debitado ao Cliente:', _currencyFormat.format(_totalDebited), isTotal: true),
          ],
        ),
      ),
    );
  }

    Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(value, style: isTotal 
            ? theme.textTheme.titleLarge?.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold) 
            : theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp)),
        ],
      ),
    );
  }

  Future<bool?> _showPinConfirmationDialog() async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isPinValid = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final navigator = Navigator.of(context);
        return AlertDialog(
          title: const Text('Confirmar Operação'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Para sua segurança, por favor insira o seu PIN de 4 dígitos.'),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.length ?? 0) < 4 ? 'PIN inválido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(false), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final storedPin = await _pinService.getPin();
                  isPinValid = storedPin == pinController.text;
                  navigator.pop(isPinValid);
                }
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );
    return result;
  }
}
