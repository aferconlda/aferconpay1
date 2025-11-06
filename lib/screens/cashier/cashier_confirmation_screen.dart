import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CashierConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const CashierConfirmationScreen({super.key, required this.transactionData});

  @override
  State<CashierConfirmationScreen> createState() =>
      _CashierConfirmationScreenState();
}

class _CashierConfirmationScreenState extends State<CashierConfirmationScreen> {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirestoreService _firestoreService = FirestoreService();
  Future<UserModel?>? _clientDataFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _clientDataFuture = _fetchClientData();
  }

  Future<UserModel?> _fetchClientData() async {
    final uid = widget.transactionData['uid'];
    if (uid == null) return null;
    return _firestoreService.getUser(uid);
  }

  String get _transactionTypeDisplay {
    return widget.transactionData['type'] == 'deposit'
        ? 'Depósito'
        : 'Levantamento';
  }

  double get _amount {
    return (widget.transactionData['amount'] as num).toDouble();
  }

  String? get _clientUid {
    return widget.transactionData['uid'] as String?;
  }

  String? get _transactionType {
    return widget.transactionData['type'] as String?;
  }

  Future<void> _onConfirmTransaction() async {
    if (_clientUid == null || _transactionType == null) {
      _showErrorSnackbar('Dados da transação inválidos. Por favor, tente novamente.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final callable = _functions.httpsCallable('processQrTransaction');
      final result = await callable.call<Map<String, dynamic>>({
        'clientUid': _clientUid,
        'amount': _amount,
        'transactionType': _transactionType,
      });

      if (!mounted) return;

      _showSuccessDialog(result.data['message'] ?? 'Transação Concluída');
    } on FirebaseFunctionsException catch (e) {
      _showErrorSnackbar(e.message ?? 'Ocorreu um erro no servidor.');
    } catch (e) {
      _showErrorSnackbar('Ocorreu um erro inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return Scaffold(
      appBar: CustomAppBar(title: Text('Confirmar $_transactionTypeDisplay')),
      body: FutureBuilder<UserModel?>(
        future: _clientDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16.h),
                  const Text(
                      'Erro: Não foi possível carregar os dados do cliente.'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                      onPressed: () =>
                          setState(() => _clientDataFuture = _fetchClientData()),
                      child: const Text('Tentar Novamente'))
                ],
              ),
            );
          }

          final client = snapshot.data!;
          final clientName = client.displayName ?? 'Nome não disponível';

          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        Text(_transactionTypeDisplay.toUpperCase(),
                            style: theme.textTheme.titleMedium),
                        SizedBox(height: 12.h),
                        Text(
                          currencyFormat.format(_amount),
                          style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary),
                        ),
                        SizedBox(height: 24.h),
                        const Divider(),
                        SizedBox(height: 12.h),
                        _buildInfoRow(context, 'Cliente', clientName),
                        _buildInfoRow(
                            context, 'ID do Cliente', widget.transactionData['uid']),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _onConfirmTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: Text('Confirmar $_transactionTypeDisplay'),
                      ),
                SizedBox(height: 12.h),
                OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Transação Concluída'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              int popCount = 0;
              Navigator.of(context).popUntil((_) => popCount++ >= 2);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
