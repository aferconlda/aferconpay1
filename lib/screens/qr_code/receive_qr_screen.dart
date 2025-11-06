import 'dart:convert';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class ReceiveQrScreen extends StatefulWidget {
  final double? amount;
  final String? transactionType;

  const ReceiveQrScreen({super.key, this.amount, this.transactionType});

  @override
  State<ReceiveQrScreen> createState() => _ReceiveQrScreenState();
}

class _ReceiveQrScreenState extends State<ReceiveQrScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _amountController = TextEditingController();
  final _screenshotController = ScreenshotController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

  UserModel? _currentUser;
  String _qrData = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(2);
    }
    _loadUserDataAndGenerateQr();
  }

  Future<void> _loadUserDataAndGenerateQr() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          if (_currentUser != null) {
            _generateQrData();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generateQrData() {
    if (_currentUser == null) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    final Map<String, dynamic> data = {
      'uid': _currentUser!.uid,
      'type': widget.transactionType ?? 'payment',
    };

    if (amount != null && amount > 0) {
      data['amount'] = amount;
    }

    setState(() {
      _qrData = jsonEncode(data);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    switch (widget.transactionType) {
      case 'deposit':
        return 'Depósito com QR Code';
      case 'withdrawal':
        return 'Levantamento com QR Code';
      default:
        return 'Receber com QR Code';
    }
  }

  String _getScreenTitle() {
    switch (widget.transactionType) {
      case 'deposit':
        return 'Apresente este código a um agente para depositar';
      case 'withdrawal':
        return 'Apresente este código a um agente para levantar';
      default:
        return 'Apresente este código para receber';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Erro: Utilizador não autenticado.'))
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, spreadRadius: 2)],
                          ),
                          child: Column(
                            children: [
                              if (_qrData.isNotEmpty)
                                QrImageView(
                                  data: _qrData,
                                  version: QrVersions.auto,
                                  size: 230.w,
                                  backgroundColor: Colors.white,
                                ),
                              SizedBox(height: 24.h),
                              Text(
                                _getScreenTitle(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _currentUser!.displayName ?? 'Nome não informado',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54),
                              ),
                              if (widget.amount != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 16.h),
                                  child: Text(
                                    _currencyFormatter.format(widget.amount),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      if (widget.amount == null)
                        _buildDynamicAmountInput(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDynamicAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DEFINIR VALOR (OPCIONAL)',
          style: theme.textTheme.labelLarge,
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: TextFormField(
            controller: _amountController,
            onChanged: (_) => _generateQrData(),
            decoration: const InputDecoration(
              labelText: 'Valor a Receber',
              prefixText: 'Kz ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}
