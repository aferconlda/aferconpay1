import 'dart:convert';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/pin_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayWithQRScreen extends StatefulWidget {
  final String qrCodeData;

  const PayWithQRScreen({super.key, required this.qrCodeData});

  @override
  State<PayWithQRScreen> createState() => _PayWithQRScreenState();
}

class _PayWithQRScreenState extends State<PayWithQRScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isProcessingPayment = false;
  UserModel? _recipient;
  String? _errorMessage;
  bool _isAmountFromQr = false;

  @override
  void initState() {
    super.initState();
    _loadRecipientData();
  }

  Future<void> _loadRecipientData() async {
    try {
      String? parsedRecipientId;
      double? qrAmount;
      String? qrDescription;

      try {
        final qrData = jsonDecode(widget.qrCodeData);
        if (qrData is Map && qrData.containsKey('uid')) {
          parsedRecipientId = qrData['uid'];
          qrAmount = (qrData['amount'] as num?)?.toDouble();
          qrDescription = qrData['description'] as String?;
        }
      } on FormatException {
        parsedRecipientId = widget.qrCodeData;
      }

      if (parsedRecipientId == null || parsedRecipientId.trim().isEmpty) {
        throw Exception('Formato do QR Code inválido.');
      }

      final recipient = await _firestoreService.getUser(parsedRecipientId);

      final currentUser = _authService.getCurrentUser();
      if (recipient.uid == currentUser?.uid) {
        throw Exception('Não pode fazer um pagamento a si mesmo.');
      }

      if (qrAmount != null) {
        _amountController.text = NumberFormat("#,##0.00", "pt_AO").format(qrAmount);
        _isAmountFromQr = true;
      }
      if (qrDescription != null) {
        _descriptionController.text = qrDescription;
      }

      if (mounted) {
        setState(() {
          _recipient = recipient;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao processar QR Code: ${e.toString().replaceAll("Exception: ", "")}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (!(_formKey.currentState?.validate() ?? false) || _recipient == null) {
      return;
    }

    final bool isPinConfirmed = await showPinConfirmationDialog(context);
    if (!isPinConfirmed || !mounted) return;

    setState(() { _isProcessingPayment = true; });

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Utilizador não autenticado.')));
      }
      setState(() { _isProcessingPayment = false; });
      return;
    }

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '.'));

      await _firestoreService.createTransferRequest(
        currentUser.uid,
        _recipient!.uid,
        amount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('O seu pedido de pagamento foi enviado e está a ser processado.'),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro no pagamento: ${e.toString().replaceAll("Exception: ", "")}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) {
        setState(() { _isProcessingPayment = false; });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipientName = _recipient?.displayName ?? 'Desconhecido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pagamento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 60),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.primaryColor.withAlpha(77)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'VOCÊ ESTÁ PAGANDO PARA',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      recipientName.substring(0, 1).toUpperCase(),
                                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    recipientName,
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _amountController,
                                    readOnly: _isAmountFromQr,
                                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText: 'Valor a Pagar',
                                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                                      suffixText: 'Kz',
                                      border: _isAmountFromQr ? InputBorder.none : const OutlineInputBorder(),
                                      filled: false,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Insira um valor.';
                                      final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
                                      if (amount == null || amount <= 0) return 'Insira um valor válido.';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  if (_descriptionController.text.isNotEmpty || !_isAmountFromQr)
                                    TextFormField(
                                      controller: _descriptionController,
                                      readOnly: _isAmountFromQr,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: 'Descrição',
                                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                                        border: _isAmountFromQr ? InputBorder.none : const OutlineInputBorder(),
                                        filled: false,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isProcessingPayment)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Confirmar e Pagar'),
                                onPressed: _processPayment,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
