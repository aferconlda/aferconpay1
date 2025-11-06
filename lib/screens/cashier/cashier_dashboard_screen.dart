import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/cashier/cashier_add_float_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String? _userId;
  Stream<UserModel>? _userStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = _authService.getCurrentUser();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_userId == null || _userStream == null) {
      return const Scaffold(
          body: Center(child: Text('Erro: Utilizador não autenticado.')));
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.h),
                _buildBalanceInfo(theme),
                SizedBox(height: 16.h),
                _buildNavigationButtons(context, theme),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(ThemeData theme) {
    return StreamBuilder<UserModel>(
      stream: _userStream!,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const Center(
              child: Text('Não foi possível carregar os seus dados.'));
        }

        final cashierData = userSnapshot.data!;
        final currencyFormat =
            NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

        return Column(
          children: [
            _buildBalanceCard(
              title: 'Meu Float (Dinheiro de Serviço)',
              amount: cashierData.floatBalance,
              icon: Icons.store,
              color: theme.colorScheme.secondary,
              format: currencyFormat,
            ),
            SizedBox(height: 12.h),
            _buildBalanceCard(
              title: 'Minhas Comissões (Ganhos)',
              amount: cashierData.totalCommissions,
              icon: Icons.trending_up,
              color: Colors.green,
              format: currencyFormat,
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_card_outlined),
          label: const Text('Adicionar Fundos ao Float'),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CashierAddFloatScreen(),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required NumberFormat format,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28.sp),
                SizedBox(width: 12.w),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 8.h),
            Text(format.format(amount),
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
