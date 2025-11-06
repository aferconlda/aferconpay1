import 'dart:async';
import 'package:afercon_pay/screens/auth/auth_gate.dart';
import 'package:afercon_pay/screens/authentication/login_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late Timer _timer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Inicia a verificação automática quando a tela é carregada
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    // Garante que o timer é cancelado para evitar fugas de memória
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    // Força o recarregamento do estado do usuário do Firebase
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user?.emailVerified ?? false) {
      _timer.cancel(); // Para o timer de verificação

      // Envia notificação de boas-vindas
      await _firestoreService.addNotification(
        user!.uid,
        'Email Verificado com Sucesso',
        'O seu endereço de email foi verificado. A sua conta está agora totalmente ativa.',
      );

      if (mounted) {
        // Navega de volta para o AuthGate para que ele decida a próxima tela (PIN ou Home)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Novo email de verificação enviado!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar email: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Verificação de Email')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_read_outlined, size: 100.sp, color: Theme.of(context).primaryColor),
              SizedBox(height: 24.h),
              Text(
                'Verifique o seu email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                'Enviámos um link de verificação para o seu email. Por favor, verifique a sua caixa de entrada (e a pasta de spam) para ativar a sua conta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              const Text(
                'Aguardando a verificação... esta janela será atualizada automaticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 32.h),
              _isSending
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      onPressed: _sendVerificationEmail,
                      label: const Text('Reenviar Email'),
                    ),
              TextButton(
                onPressed: () {
                  _authService.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Voltar para o Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
