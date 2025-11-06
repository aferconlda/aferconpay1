import 'package:afercon_pay/screens/credit/credit_main_screen.dart';
import 'package:afercon_pay/screens/faq/faq_screen.dart';
import 'package:afercon_pay/screens/home/home_screen.dart';
import 'package:afercon_pay/screens/p2p_exchange/p2p_marketplace_screen.dart';
import 'package:afercon_pay/screens/profile/profile_screen.dart';
import 'package:afercon_pay/screens/transactions/transaction_history_screen.dart';
import 'package:afercon_pay/theme/theme_provider.dart';
import 'package:afercon_pay/widgets/notification_icon_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notifications/notifications_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final List<Widget> screens = [
        const HomeScreen(),
        const TransactionHistoryScreen(),
        const P2PMarketplaceScreen(),
        const CreditMainScreen(),
        const FaqScreen(),
      ];
    final List<String> titles = [
        'Afercon Pay',
        'Histórico de Transações',
        'Mercado P2P',
        'Crédito Afercon',
        'Ajuda (FAQ)',
      ];
    final List<BottomNavigationBarItem> navBarItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Histórico',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Mercado',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Crédito',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Ajuda',
        ),
      ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Alternar Tema',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NotificationIconWithBadge(
              icon: Icons.notifications_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Perfil',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
