import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/transaction_service.dart'; 
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/pin_confirmation_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _transactionService = TransactionService();

  User? _currentUser;
  UserModel? _recipientUser;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _findRecipient() async {
    if (_recipientController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _recipientUser = null;
      _searchError = null;
    });

    try {
      final recipient = await _firestoreService.findUserByContact(_recipientController.text.trim());

      if (recipient == null) {
        setState(() => _searchError = 'Nenhum utilizador encontrado com este contacto.');
      } else if (recipient.uid == _currentUser?.uid) {
        setState(() => _searchError = 'Não pode transferir para si mesmo.');
      } else {
        setState(() => _recipientUser = recipient);
      }
    } catch (e) {
      setState(() => _searchError = 'Ocorreu um erro na procura. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _processTransfer() async {
    final recipient = _recipientUser;

    if (!(_formKey.currentState?.validate() ?? false) || recipient == null || _isProcessing) return;

    final bool isPinConfirmed = await showPinConfirmationDialog(context);
    if (!isPinConfirmed || !mounted) return;

    setState(() => _isProcessing = true);

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final description = _descriptionController.text;
    final recipientId = recipient.uid;
    final recipientName = recipient.displayName ?? 'desconhecido';

    try {
      await _transactionService.p2pTransfer(
        recipientId: recipientId,
        amount: amount,
        description: description.isNotEmpty ? description : 'Transferência para $recipientName',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transferência realizada com sucesso!'),
            backgroundColor: Colors.green[600],
          ),
        );
        FirebaseAnalytics.instance.logEvent(name: 'p2p_transfer', parameters: {'amount': amount, 'currency': 'AOA'});
        _formKey.currentState?.reset();
        _recipientController.clear();
        _amountController.clear();
        _descriptionController.clear();
        setState(() => _recipientUser = null);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Não foi possível concluir a transferência. Tente novamente.';
        if (e is Exception) {
            final message = e.toString().toLowerCase();
            if (message.contains('insufficient funds')) {
                errorMessage = 'O seu saldo é insuficiente para esta transferência.';
            } else if (message.contains('user not found')) {
                errorMessage = 'O destinatário não foi encontrado.';
            }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
        if (mounted) {
            setState(() => _isProcessing = false);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Transferir')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Utilizador não autenticado.'))
              : StreamBuilder<UserModel?>(
                  stream: _firestoreService.getUserStream(_currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData)
{                      return const Center(child: Text('Não foi possível carregar os dados do utilizador.'));
}
                    final user = snapshot.data!;
                    final userBalance = user.balance['AOA'] ?? 0.0;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSearchField(),
                            if (_searchError != null)
                              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_searchError!, style: TextStyle(color: theme.colorScheme.error))),
                            const SizedBox(height: 24),
                            if (_recipientUser != null)
                              _buildRecipientCard(_recipientUser),
                            if (_recipientUser != null) ...[
                              const SizedBox(height: 24),
                              Text('Saldo disponível: ${NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(userBalance)}', style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(labelText: 'Montante', suffixText: 'Kz'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Insira um montante.';
                                  final amount = double.tryParse(v.replaceAll(',', '.'));
                                  if (amount == null || amount <= 0) return 'Insira um montante válido.';
                                  if (amount > userBalance) return 'Saldo insuficiente.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
                              ),
                            ],
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Transferir Agora'),
                              onPressed: (_recipientUser != null && !_isProcessing) ? _processTransfer : null,
                            ),
                            if (_isProcessing)
                              const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _recipientController,
      decoration: InputDecoration(
        labelText: 'Email ou Nº de Telemóvel',
        suffixIcon: _isSearching
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(icon: const Icon(Icons.search), onPressed: _findRecipient),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (v) => (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
      onChanged: (v) {
        if (_recipientUser != null || _searchError != null) {
          setState(() {
            _recipientUser = null;
            _searchError = null;
          });
        }
      },
    );
  }

  Widget _buildRecipientCard(UserModel? recipientData) {
    if (recipientData == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor,
              child: Text(
                recipientData.displayName?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DESTINATÁRIO', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(recipientData.displayName ?? 'Nome não disponível', style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(recipientData.email ?? recipientData.phoneNumber ?? 'Contacto não disponível', style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
