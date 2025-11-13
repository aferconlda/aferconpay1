import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/cashier_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/pin_service.dart';
import 'package:afercon_pay/utils/app_validators.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  
  // Serviços
  final _firestoreService = FirestoreService();
  final _cashierService = CashierService();
  final _pinService = PinService();

  final _userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final pinIsValid = await _validatePin();
    if (!pinIsValid) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN de segurança incorreto!'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _isLoading = true);

    try {
      await _cashierService.withdrawCommissionToBalance(amount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comissão levantada para o seu saldo principal com sucesso!'),
            backgroundColor: Colors.green[600],
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _validatePin() async {
    final storedPin = await _pinService.getPin();
    return storedPin == _pinController.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Levantar Comissão')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: StreamBuilder<UserModel>(
          stream: _firestoreService.getUserStream(_userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Utilizador não encontrado.'));
            }

            final user = snapshot.data!;
            // CORREÇÃO: Usa o campo correto 'totalCommissions'
            final commissionBalance = user.totalCommissions;
            final minimumWithdrawal = 5000.00; // Mínimo de 5000 Kz

            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(
                    context,
                    'Saldo de Comissão Disponível',
                    currencyFormat.format(commissionBalance),
                    Icons.card_giftcard,
                    theme.colorScheme.primary,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Insira o montante que deseja levantar para a sua conta principal.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Montante a Levantar',
                      prefixText: 'Kz ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um montante.';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'O montante deve ser positivo.';
                      }
                      if (amount < minimumWithdrawal) {
                        return 'O levantamento mínimo é de ${currencyFormat.format(minimumWithdrawal)}.';
                      }
                      if (amount > commissionBalance) {
                        return 'Não tem saldo de comissão suficiente.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'PIN de Segurança',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: AppValidators.pin,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Pedir Levantamento'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(25),
              radius: 24.r,
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.black54),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
