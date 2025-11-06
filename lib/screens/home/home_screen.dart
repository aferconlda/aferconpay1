import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/auth/auth_gate.dart';
import 'package:afercon_pay/screens/home/widgets/action_buttons_grid.dart';
import 'package:afercon_pay/screens/home/widgets/balance_card.dart';
import 'package:afercon_pay/screens/home/widgets/recent_transactions.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Stream<UserModel>? _userStream;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserIdAndPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // O utilizador pode ter ido às definições para ativar a permissão.
      // Vamos verificar novamente para garantir que a UI reflete o estado atual.
       _requestPermissions();
    }
  }

  Future<void> _loadUserIdAndPermissions() async {
    final user = _authService.getCurrentUser();
    if (mounted) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
          _userStream = _firestoreService.getUserStream(user.uid);
        });
        // Apenas pedir permissões se o utilizador estiver autenticado.
        await _requestPermissions();
      } else {
        setState(() {
           _userId = null;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    // Não é necessário esperar pela conclusão, pois os pop-ups de permissão
    // são geridos pelo SO e não bloqueiam a UI principal.
    [ 
      Permission.camera,
      Permission.notification,
      Permission.locationWhenInUse,
    ].request();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const AuthGate();
    }

    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    return StreamBuilder<UserModel>(
      stream: _userStream,
      builder: (context, snapshot) {
        return Scaffold(
          body: _buildContent(context, snapshot, currencyFormat),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<UserModel> userSnapshot,
    NumberFormat currencyFormat,
  ) {
    if (userSnapshot.hasError) {
      return Center(child: Text('Erro ao carregar dados: ${userSnapshot.error}'));
    }

    final user = userSnapshot.data;
    final userName = user?.displayName ?? 'Utilizador';
    final isLoading = userSnapshot.connectionState == ConnectionState.waiting || !userSnapshot.hasData;

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Text(
            '${_getGreeting()}, ${isLoading ? 'a carregar...' : userName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        BalanceCard(
          balance: user?.balance ?? 0,
          format: currencyFormat,
          isLoading: isLoading,
        ),
        SizedBox(height: 24.h),
        const ActionButtonsGrid(),
        SizedBox(height: 24.h),
        // Garante que o ID do utilizador não é nulo antes de construir a secção de transações
        if (_userId != null) 
          _buildTransactionsSection(context, _userId!, currencyFormat),
      ],
    );
  }

  Widget _buildTransactionsSection(BuildContext context, String userId, NumberFormat format) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _firestoreService.getTransactionsStream(userId),
      builder: (context, transactionSnapshot) {
        final isLoadingTransactions = transactionSnapshot.connectionState == ConnectionState.waiting;
        final transactions = transactionSnapshot.data ?? [];
        
        return RecentTransactions(
          transactions: transactions,
          format: format,
          isLoading: isLoadingTransactions,
        );
      },
    );
  }
}
