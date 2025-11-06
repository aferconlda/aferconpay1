import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/screens/credit/business_credit_screen.dart';
import 'package:afercon_pay/screens/credit/personal_credit_screen.dart';
import 'package:afercon_pay/screens/kyc/kyc_verification_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/credit_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditMainScreen extends StatefulWidget {
  const CreditMainScreen({super.key});

  @override
  State<CreditMainScreen> createState() => _CreditMainScreenState();
}

class _CreditMainScreenState extends State<CreditMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreditService _creditService = CreditService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _userId;
  Stream<UserModel>? _userStream;
  Stream<QuerySnapshot>? _creditHistoryStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = _authService.getCurrentUser();
    if (mounted) {
      if (currentUser != null) {
        setState(() {
          _userId = currentUser.uid;
          _userStream = _firestoreService.getUserStream(_userId!);
          _creditHistoryStream = _creditService.getCreditHistory(_userId!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleCreditNavigation(BuildContext context, UserModel user, String creditType) {
    if (user.kycStatus == KycStatus.approved) {
      final screen = creditType == 'personal' ? const PersonalCreditScreen() : const BusinessCreditScreen();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      return;
    }

    String message;
    switch (user.kycStatus) {
      case KycStatus.pending:
        message = 'A sua identidade está pendente de verificação.';
        break;
      case KycStatus.rejected:
        message = 'A sua verificação de identidade foi rejeitada. Por favor, submeta novamente.';
        break;
      default:
        message = 'É necessário verificar a sua identidade para solicitar um crédito.';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycVerificationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userId == null) {
      return const Scaffold(body: Center(child: Text("Utilizador não autenticado.")));
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Novo Pedido'),
                Tab(text: 'Meus Pedidos'),
              ],
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha(179),
              indicatorColor: theme.colorScheme.onPrimary,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewRequestTab(context),
                _buildHistoryTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewRequestTab(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Não foi possível carregar os dados do utilizador.'));
        }

        final user = snapshot.data!;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCreditOptionCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'Crédito Pessoal',
                  subtitle: 'Para as suas metas individuais.',
                  onTap: () => _handleCreditNavigation(context, user, 'personal'),
                ),
                const SizedBox(height: 24),
                _buildCreditOptionCard(
                  context,
                  icon: Icons.business_center_outlined,
                  title: 'Crédito Empresarial',
                  subtitle: 'Para impulsionar o seu negócio.',
                  onTap: () => _handleCreditNavigation(context, user, 'business'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditOptionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withAlpha(179))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _creditHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Ainda não tem pedidos de crédito.'));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro ao carregar o histórico.'));
        }

        final requests = snapshot.data!.docs;
        final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);
        final dateFormat = DateFormat('dd/MM/yyyy');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            final status = request['status'] ?? 'desconhecido';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: Icon(_getIconForStatus(status), color: _getColorForStatus(context, status)),
                title: Text(request['type'] == 'personal' ? 'Crédito Pessoal' : 'Crédito Empresarial'),
                subtitle: Text('Pedido em: ${request.containsKey('applicationDate') ? dateFormat.format((request['applicationDate'] as Timestamp).toDate()) : 'N/A'}'),
                trailing: Text(
                  currencyFormat.format(request['amount'] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForStatus(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'approved':
        return theme.primaryColor;
      case 'rejected':
        return theme.colorScheme.error;
      case 'pending':
        return Colors.orange.shade400;
      default:
        return theme.textTheme.bodyMedium!.color!.withAlpha(128);
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
        return Icons.hourglass_empty_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
