import 'package:afercon_pay/models/commission_transaction_model.dart';
import 'package:afercon_pay/screens/cashier/cashier_withdrawal_request_screen.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashierEarningsScreen extends StatefulWidget {
  const CashierEarningsScreen({super.key});

  @override
  State<CashierEarningsScreen> createState() => _CashierEarningsScreenState();
}

class _CashierEarningsScreenState extends State<CashierEarningsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  late Stream<double> _commissionBalanceStream;
  late Stream<List<CommissionTransactionModel>> _commissionHistoryStream;

  @override
  void initState() {
    super.initState();
    if (_userId != null) {
      _commissionBalanceStream = _firestoreService.getCommissionBalanceStream(_userId!);
      _commissionHistoryStream = _firestoreService.getCommissionHistoryStream(_userId!);
    }
  }

  void _navigateToRequestScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CashierWithdrawalRequestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erro: Utilizador não autenticado.'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Meus Ganhos'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<double>(
              stream: _commissionBalanceStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Erro ao carregar saldo: ${snapshot.error}');
                }
                final balance = snapshot.data ?? 0.0;
                return Column(
                  children: [
                    _buildBalanceCard(theme, balance),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.request_page_outlined),
                      label: const Text('Solicitar Levantamento'),
                      onPressed: _navigateToRequestScreen,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Histórico de Comissões', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<CommissionTransactionModel>>(
                stream: _commissionHistoryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // Provide a more user-friendly error message
                    return const Center(
                      child: Text(
                        'Ocorreu um erro ao carregar o histórico. Por favor, tente novamente mais tarde.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Ainda não ganhou nenhuma comissão.'),
                    );
                  }
                  return _buildHistoryList(theme, snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, double balance) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
    return Card(
      elevation: 5,
      color: theme.colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'SALDO DE COMISSÃO DISPONÍVEL',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(ThemeData theme, List<CommissionTransactionModel> history) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: '');
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        
        final requestId = item.originalRequestId ?? 'N/A';
        final refId = (requestId.length >= 6) ? requestId.substring(0, 6) : requestId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.green),
            title: const Text('Comissão Recebida'),
            subtitle: Text(
              'Ref: $refId - ${DateFormat('dd/MM/yy HH:mm').format(item.date)}',
            ),
            trailing: Text(
              '+ ${currencyFormat.format(item.amount)} Kz',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
