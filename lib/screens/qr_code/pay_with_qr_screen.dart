
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/transaction_service.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/pin_confirmation_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PayWithQrScreen extends StatefulWidget {
  final String recipientId;
  final double? amount;

  const PayWithQrScreen({super.key, required this.recipientId, this.amount});

  @override
  State<PayWithQrScreen> createState() => _PayWithQrScreenState();
}

class _PayWithQrScreenState extends State<PayWithQrScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController(text: 'Pagamento via QR Code');

  bool _isLoading = true;
  bool _isProcessingPayment = false;
  UserModel? _recipient;
  UserModel? _currentUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(2);
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final authUser = _authService.getCurrentUser();
      if (authUser == null) {
        throw Exception('Utilizador não autenticado.');
      }

      final [recipient, currentUser] = await Future.wait([
        _firestoreService.getUser(widget.recipientId),
        _firestoreService.getUser(authUser.uid),
      ]);

      if (recipient == null) {
        throw Exception('O destinatário do pagamento não foi encontrado.');
      }
      if (currentUser == null) {
        throw Exception('Não foi possível carregar os seus dados.');
      }
      if (recipient.uid == currentUser.uid) {
        throw Exception('Não pode fazer um pagamento a si mesmo.');
      }

      if (mounted) {
        setState(() {
          _recipient = recipient;
          _currentUser = currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: ${e.toString().replaceAll("Exception: ", "")}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (!(_formKey.currentState?.validate() ?? false) || _recipient == null) {
      return;
    }

    // FINAL AUTH CHECK: Ensure the user is still authenticated right before the transaction.
    if (FirebaseAuth.instance.currentUser == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A sua sessão expirou. Por favor, faça login novamente.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final bool isPinConfirmed = await showPinConfirmationDialog(context);
    if (!isPinConfirmed || !mounted) return;

    setState(() { _isProcessingPayment = true; });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '.'));

      // CORRECTED: Fixed the typo in the method name from p_2_p_transfer to p2pTransfer
      await _transactionService.p2pTransfer(
        recipientId: _recipient!.uid,
        amount: amount,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Pagamento efetuado com sucesso!'),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      // The error from the service is already user-friendly
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll("Exception: ", "")),
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
    final isAmountFromQr = widget.amount != null;

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
                                      recipientName.isNotEmpty ? recipientName.substring(0, 1).toUpperCase() : 'U',
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
                                    readOnly: isAmountFromQr,
                                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText: 'Valor a Pagar',
                                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                                      suffixText: 'Kz',
                                      border: const OutlineInputBorder(),
                                      filled: false,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Insira um valor.';
                                      final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
                                      if (amount == null || amount <= 0) return 'Insira um valor válido.';
                                      
                                      final balance = _currentUser?.balance['AOA'] ?? 0.0;
                                      if (amount > balance) {
                                        return 'Saldo insuficiente. Saldo atual: $balance Kz';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                      controller: _descriptionController,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: 'Descrição',
                                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                                        border: const OutlineInputBorder(),
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
