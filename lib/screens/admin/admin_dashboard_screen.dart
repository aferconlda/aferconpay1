import 'package:afercon_pay/screens/admin/admin_statistics_screen.dart';
import 'package:afercon_pay/screens/admin/credit_applications_screen.dart';
import 'package:afercon_pay/screens/admin/transaction_management_screen.dart';
import 'package:afercon_pay/screens/admin/user_management_screen.dart';
import 'package:afercon_pay/screens/admin/verification_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Painel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16.w),
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.bar_chart_outlined, // Ícone de estatísticas
            label: 'Estatísticas',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AdminStatisticsScreen(),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.people_outline,
            label: 'Gerir Utilizadores',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const UserManagementScreen(),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.verified_user_outlined,
            label: 'Verificações KYC',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AdminVerificationScreen(),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Pedidos de Crédito',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CreditApplicationsScreen(),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.receipt_long_outlined,
            label: 'Depósitos e Levantamentos',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const TransactionManagementScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 6,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.sp, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 12.h),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
