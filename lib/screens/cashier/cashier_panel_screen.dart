import 'dart:convert';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/cashier/cashier_add_float_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/screens/cashier/cashier_confirmation_screen.dart';
import 'package:afercon_pay/screens/cashier/cashier_earnings_screen.dart';
import 'package:afercon_pay/screens/qr_code/scan_qr_screen.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CashierPanelScreen extends StatefulWidget {
  const CashierPanelScreen({super.key});

  @override
  State<CashierPanelScreen> createState() => _CashierPanelScreenState();
}

class _CashierPanelScreenState extends State<CashierPanelScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Stream<UserModel>? _cashierStream;
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
        _cashierStream = _firestoreService.getUserStream(currentUser.uid);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAndProcessQr(BuildContext context, String expectedType) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final String? qrCodeData = await navigator.push<String>(
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );

    if (qrCodeData == null || !mounted) return;

    try {
      final Map<String, dynamic> data = jsonDecode(qrCodeData);
      if (data['type'] != expectedType) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  'QR Code inválido. É esperado um código de ${expectedType == 'deposit' ? 'depósito' : 'levantamento'}.')),
        );
        return;
      }
      if (data['uid'] == null || data['amount'] == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('QR Code inválido ou corrompido.')),
        );
        return;
      }

      await navigator.push(MaterialPageRoute(
        builder: (_) => CashierConfirmationScreen(transactionData: data),
      ));
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Erro ao ler o QR Code. Formato desconhecido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Painel do Caixa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Meus Ganhos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CashierEarningsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildQrCodeActions(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQrCodeActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Ações do Caixa',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        _buildFloatBalanceCard(context),
        SizedBox(height: 24.h),
        _buildActionButton(
          context: context,
          icon: Icons.add_card_outlined,
          label: 'Adicionar Fundos ao Float',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const CashierAddFloatScreen()),
            );
          },
        ),
        SizedBox(height: 16.h),
        _buildActionButton(
          context: context,
          icon: Icons.qr_code_scanner_outlined,
          label: 'Ler QR para Depósito',
          onTap: () => _scanAndProcessQr(context, 'deposit'),
        ),
        SizedBox(height: 16.h),
        _buildActionButton(
          context: context,
          icon: Icons.qr_code_scanner_outlined,
          label: 'Ler QR para Levantamento',
          onTap: () => _scanAndProcessQr(context, 'withdrawal'),
        ),
      ],
    );
  }

  Widget _buildFloatBalanceCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        child: StreamBuilder<UserModel>(
          stream: _cashierStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)));
            }
            if (!snapshot.hasData) {
              return const Text('Saldo flutuante indisponível.');
            }

            final cashierData = snapshot.data!;
            final floatBalance = cashierData.floatBalance;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meu Saldo Float',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(floatBalance),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24.r),
        label: Text(label),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          textStyle:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
