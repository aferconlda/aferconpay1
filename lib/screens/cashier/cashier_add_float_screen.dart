import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/cashier_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CashierAddFloatScreen extends StatefulWidget {
  const CashierAddFloatScreen({super.key});

  @override
  State<CashierAddFloatScreen> createState() => _CashierAddFloatScreenState();
}

class _CashierAddFloatScreenState extends State<CashierAddFloatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _cashierService = CashierService();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _isLoading = true);

    try {
      await _cashierService.addFloatFromBalance(amount);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saldo float carregado com sucesso!'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Carregar Saldo Float')),
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getUserStream(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(
                child: Text('Não foi possível carregar os dados do utilizador.'));
          }

          final user = snapshot.data!;
          final personalBalance = user.aoaBalance;
          final floatBalance = user.floatBalance;

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBalanceInfoCard(
                    theme,
                    'Saldo Principal Disponível',
                    currencyFormat.format(personalBalance),
                    Icons.account_balance_wallet,
                    theme.colorScheme.primary,
                  ),
                  SizedBox(height: 16.h),
                  _buildBalanceInfoCard(
                    theme,
                    'Saldo Float Atual',
                    currencyFormat.format(floatBalance),
                    Icons.storefront_outlined,
                    theme.colorScheme.secondary,
                  ),
                  SizedBox(height: 32.h),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Montante a Carregar',
                      prefixText: 'Kz ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um montante.';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'O montante deve ser positivo.';
                      }
                      if (amount > personalBalance) {
                        return 'Não tem saldo principal suficiente.';
                      }
                      return null;
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        textStyle: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirmar Carregamento'),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceInfoCard(ThemeData theme, String title, String amount,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(icon, size: 32.sp, color: color),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54)),
                Text(amount,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
