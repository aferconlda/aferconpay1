import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:afercon_pay/screens/credit/credit_application_screen.dart';
import 'package:afercon_pay/services/credit_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PersonalCreditScreen extends StatefulWidget {
  const PersonalCreditScreen({super.key});

  @override
  PersonalCreditScreenState createState() => PersonalCreditScreenState();
}

class PersonalCreditScreenState extends State<PersonalCreditScreen> {
  final CreditService _creditService = CreditService();
  late final FirestoreService _firestoreService;
  late final AuthService _authService;
  String? _userId;

  Stream<UserModel>? _userStream;
  bool _isLoading = true;

  double _loanAmount = 0;
  double _loanMonths = 3;
  Map<String, double> _loanDetails = {};

  final double _maxLoanAmount = 1000000;
  final double _minMonths = 3;
  final double _maxMonths = 24;
  final double _analysisFee = 500.0;

  final currencyFormat =
      NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _firestoreService = context.read<FirestoreService>();
    _authService = context.read<AuthService>();
    _loadUserData();
    _calculateDetails();
  }

  void _loadUserData() {
    final currentUser = _authService.getCurrentUser();
    if (mounted) {
      if (currentUser != null) {
        setState(() {
          _userId = currentUser.uid;
          _userStream = _firestoreService.getUserStream(_userId!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateDetails() {
    setState(() {
      _loanDetails = _creditService.calculateLoanDetails(
        _loanAmount,
        _loanMonths.toInt(),
        'personal',
      );
    });
  }

  void _navigateToApplicationForm() {
    if (_loanAmount > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreditApplicationScreen(
            loanAmount: _loanAmount,
            loanMonths: _loanMonths.toInt(),
            creditType: 'personal',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: Text('Simulador de Crédito Pessoal'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null || _userStream == null) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: Text('Simulador de Crédito Pessoal'),
        ),
        body: Center(child: Text("Utilizador não autenticado.")),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Simulador de Crédito Pessoal'),
      ),
      body: StreamBuilder<UserModel>(
        stream: _userStream!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(
                child: Text("Não foi possível carregar os dados."));
          }

          final user = snapshot.data!;
          final currentBalance = user.balance;

          final bool hasSufficientBalance = currentBalance >= _analysisFee;
          final bool isButtonEnabled = _loanAmount > 0 && hasSufficientBalance;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSimulatorCard(),
                const SizedBox(height: 32),
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildFeeInformationCard(),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed:
                          isButtonEnabled ? _navigateToApplicationForm : null,
                      child: const Text('Avançar para o Pedido'),
                    ),
                    if (_loanAmount > 0 && !hasSufficientBalance)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Saldo insuficiente (${currencyFormat.format(currentBalance)}) para cobrir a taxa de análise de ${currencyFormat.format(_analysisFee)}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeeInformationCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxa de Análise',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(_analysisFee),
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta taxa não reembolsável cobre os custos administrativos e a avaliação do seu perfil de crédito.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(204)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor do Empréstimo',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(currencyFormat.format(_loanAmount),
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            Slider(
              value: _loanAmount,
              min: 0,
              max: _maxLoanAmount,
              divisions: 200,
              label: currencyFormat.format(_loanAmount),
              onChanged: (value) {
                setState(() {
                  _loanAmount = value;
                });
              },
              onChangeEnd: (value) => _calculateDetails(),
            ),
            const SizedBox(height: 16),
            Text('Prazo de Pagamento (Meses)',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text('${_loanMonths.toInt()} meses',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            Slider(
              value: _loanMonths,
              min: _minMonths,
              max: _maxMonths,
              divisions: (_maxMonths - _minMonths).toInt(),
              label: '${_loanMonths.toInt()} meses',
              onChanged: (value) {
                setState(() {
                  _loanMonths = value;
                });
              },
              onChangeEnd: (value) => _calculateDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final monthlyPayment = _loanDetails['monthlyPayment'] ?? 0;
    final totalInterest = _loanDetails['totalInterest'] ?? 0;
    final totalRepayment = _loanDetails['totalRepayment'] ?? 0;
    final interestRate = (_loanDetails['interestRate'] ?? 0) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo da Simulação', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSummaryRow(
                'Taxa de Juro Mensal', '${interestRate.toStringAsFixed(1)}%'),
            const Divider(),
            _buildSummaryRow(
                'Juros a Pagar', currencyFormat.format(totalInterest)),
            const Divider(),
            _buildSummaryRow(
                'Valor Total a Pagar', currencyFormat.format(totalRepayment),
                isTotal: true),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('Prestação Mensal Estimada',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(monthlyPayment),
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.bodyMedium),
        Text(value,
            style: isTotal
                ? theme.textTheme.titleLarge?.copyWith(fontSize: 18)
                : theme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
      ],
    );
  }
}
