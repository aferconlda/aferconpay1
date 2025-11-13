import 'package:afercon_pay/models/credit_application_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BusinessCreditScreen extends StatefulWidget {
  const BusinessCreditScreen({super.key});

  @override
  State<BusinessCreditScreen> createState() => _BusinessCreditScreenState();
}

class _BusinessCreditScreenState extends State<BusinessCreditScreen> {
  final _firestoreService = FirestoreService();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  final _amountController = TextEditingController();
  final _monthsController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _monthsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitApplication({
    required double amount,
    required int months,
    required String reason,
    required String userId,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final application = CreditApplicationModel(
      id: '', // Firestore will generate it
      userId: userId,
      amount: amount,
      months: months,
      reason: reason,
      creditType: 'business',
      status: 'pending',
      createdAt: Timestamp.now(),
    );

    try {
      await _firestoreService.createCreditApplication(application);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pedido de crédito enviado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar o pedido: $e')),
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
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Crédito Empresarial')),
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getUserStream(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Utilizador não encontrado.'));
          }

          final user = snapshot.data!;
          final isEligible = user.kycStatus == KycStatus.approved &&
              user.role == 'business_owner';

          if (!isEligible) {
            return _buildEligibilityError(user);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Solicite crédito para a sua empresa.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Montante Desejado',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um montante.';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'O montante deve ser um número positivo.';
                      }
                      if (user.aoaBalance >= 0 && amount > user.aoaBalance * 0.5) {
                        return 'O montante não pode exceder 50% do seu saldo atual (${currencyFormat.format(user.aoaBalance * 0.5)}).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _monthsController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Meses para Reembolso',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o número de meses.';
                      }
                      final months = int.tryParse(value);
                      if (months == null || months <= 0) {
                        return 'O número de meses deve ser um inteiro positivo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo do Pedido',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, descreva o motivo do pedido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _submitApplication(
                              amount: double.parse(_amountController.text),
                              months: int.parse(_monthsController.text),
                              reason: _reasonController.text,
                              userId: _userId,
                            ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Enviar Pedido'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEligibilityError(UserModel user) {
    String message;
    if (user.kycStatus != KycStatus.approved) {
      message =
          'A sua conta precisa de ter o KYC aprovado para solicitar crédito.';
    } else if (user.role != 'business_owner') {
      message =
          'Apenas contas de proprietário de empresa (Business Owner) podem solicitar crédito empresarial.';
    } else {
      message = 'Não é elegível para crédito empresarial neste momento.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
