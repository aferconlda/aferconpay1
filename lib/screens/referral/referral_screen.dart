import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _referralCode;
  int _referralsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user != null && mounted) {
        final code = await _firestoreService.getOrCreateReferralCode(user.uid);
        final count = await _firestoreService.getReferralsCount(code);

        if (mounted) {
          setState(() {
            _referralCode = code;
            _referralsCount = count;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro ao carregar os dados: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyCode() {
    if (_referralCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de convite não disponível. Tente novamente.')),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: _referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código de convite copiado para a área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Convidar Amigos')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_referralCode == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Não foi possível carregar os seus dados de convite.', textAlign: TextAlign.center,),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReferralData, child: const Text('Tentar Novamente')),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.people_alt_rounded, size: 100.sp, color: theme.primaryColor),
        SizedBox(height: 24.h),
        Text(
          'Convide os seus amigos e ganhem ambos!',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          'Partilhe o seu código de convite exclusivo. Quando um amigo se registar com este código, ambos recebem um bónus.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 48.h),
        _buildStatsRow(theme),
        SizedBox(height: 24.h),
        Text(
          'O SEU CÓDIGO',
          style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 1.5.w),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Card(
          color: theme.colorScheme.surface.withAlpha(150),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              _referralCode!,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _copyCode,
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Copiar Código'),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              'Amigos Convidados',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            SizedBox(height: 4.h),
            Text(
              _referralsCount.toString(),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
