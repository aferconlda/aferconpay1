import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/credit_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditApplicationScreen extends StatefulWidget {
  final double loanAmount;
  final int loanMonths;
  final String creditType;

  const CreditApplicationScreen({
    super.key,
    required this.loanAmount,
    required this.loanMonths,
    required this.creditType,
  });

  @override
  CreditApplicationScreenState createState() => CreditApplicationScreenState();
}

class CreditApplicationScreenState extends State<CreditApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();

  final CreditService _creditService = CreditService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isSubmitting = false;
  bool _isPageLoading = true;
  Map<String, double> _loanDetails = {};

  final currencyFormat =
      NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          if (_currentUser != null) {
            _nameController.text = _currentUser!.displayName ?? '';
          }
          _loanDetails = _creditService.calculateLoanDetails(
              widget.loanAmount, widget.loanMonths, widget.creditType);
          _isPageLoading = false;
        });
      } else {
        setState(() {
          _isPageLoading = false;
        });
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Utilizador não autenticado. Não é possível submeter o pedido.')));
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final applicationData = {
        'userId': _currentUser!.uid,
        'fullName': _nameController.text,
        'amount': widget.loanAmount,
        'termInMonths': widget.loanMonths,
        'reason': _reasonController.text,
        'type': widget.creditType,
      };

      await _creditService.applyForCredit(applicationData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O seu pedido foi submetido com sucesso!')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ocorreu um erro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Finalizar Pedido de Crédito'),
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummarySection(),
                    const SizedBox(height: 32),
                    _buildFormFields(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    final monthlyPayment = _loanDetails['monthlyPayment'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do Pedido', style: theme.textTheme.titleLarge),
            const Divider(),
            _buildSummaryRow('Tipo:',
                widget.creditType == 'personal' ? 'Pessoal' : 'Empresarial'),
            _buildSummaryRow(
                'Valor Solicitado:', currencyFormat.format(widget.loanAmount)),
            _buildSummaryRow('Prazo:', '${widget.loanMonths} meses'),
            _buildSummaryRow(
                'Prestação Mensal:', currencyFormat.format(monthlyPayment),
                isHighlight: true),
            if (widget.creditType == 'business') ...[
              const Divider(),
              _buildSummaryRow('Taxa de Análise:', currencyFormat.format(1000)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
              labelText: 'Nome Completo (como no seu documento)'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'O nome é obrigatório.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(
              labelText: 'Motivo do Pedido', alignLabelWithHint: true),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().length < 10) {
              return 'Por favor, detalhe o motivo com pelo menos 10 caracteres.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return _isSubmitting
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _submitApplication,
            child: const Text('Confirmar e Enviar Pedido'),
          );
  }

  Widget _buildSummaryRow(String title, String value, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    final valueStyle = TextStyle(
      fontSize: 16,
      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
      color: isHighlight ? theme.primaryColor : theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
