import 'package:afercon_pay/services/cashier_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CashierWithdrawalRequestScreen extends StatefulWidget {
  const CashierWithdrawalRequestScreen({super.key});

  @override
  State<CashierWithdrawalRequestScreen> createState() =>
      _CashierWithdrawalRequestScreenState();
}

class _CashierWithdrawalRequestScreenState
    extends State<CashierWithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  
  final _cashierService = CashierService();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _beneficiaryNameController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final withdrawalData = {
      'amount': amount,
      'iban': _ibanController.text,
      'bankName': _bankNameController.text,
      'beneficiaryName': _beneficiaryNameController.text,
    };

    try {
      await _cashierService.requestCashierWithdrawal(withdrawalData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pedido de levantamento enviado com sucesso! Aguarda aprovação.'),
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
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Solicitar Levantamento'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preencha os dados para o levantamento da sua comissão.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montante a Levantar (Kz)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o montante.';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Por favor, insira um número válido.';
                  }
                  if (amount <= 0) {
                    return 'O montante deve ser maior que zero.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _beneficiaryNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Beneficiário',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira o nome do beneficiário.' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _ibanController,
                decoration: const InputDecoration(
                  labelText: 'IBAN',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira o IBAN.' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Banco',
                  prefixIcon: Icon(Icons.apartment),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira o nome do banco.' : null,
              ),
              SizedBox(height: 32.h),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      child: const Text('ENVIAR PEDIDO'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
