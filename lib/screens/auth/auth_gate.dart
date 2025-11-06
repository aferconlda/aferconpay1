import 'package:afercon_pay/screens/authentication/login_screen.dart';
import 'package:afercon_pay/screens/authentication/verify_email_screen.dart';
import 'package:afercon_pay/screens/home/home_router_screen.dart';
import 'package:afercon_pay/screens/security/pin_setup_screen.dart';
import 'package:afercon_pay/services/auth_service.dart'; // PASSO 1: Importar o nosso serviço
import 'package:afercon_pay/services/pin_service.dart';
import 'package:afercon_pay/widgets/inactivity_detector.dart';
import 'package:firebase_auth/firebase_auth.dart'; // O import do User é necessário
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final PinService _pinService = PinService();
  // PASSO 2: Instanciar o nosso AuthService (será a instância Singleton)
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // PASSO 3: Ouvir o stream do nosso AuthService em vez do FirebaseAuth
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        // A lógica de "loading" pode precisar de ajuste dependendo do comportamento inicial do stream
        if (authSnapshot.connectionState == ConnectionState.waiting && !authSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;

          // A lógica de verificação de email e PIN permanece a mesma
          if (!user.emailVerified) {
            return const VerifyEmailScreen();
          }

          return FutureBuilder<bool>(
            future: _pinService.isPinSet(),
            builder: (context, pinSnapshot) {
              if (pinSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (pinSnapshot.hasData && pinSnapshot.data == true) {
                return const InactivityDetector(
                  child: HomeRouterScreen(), 
                );
              } else {
                return PopScope(
                  canPop: false,
                  child: PinSetupScreen(
                    onPinSet: () {
                      setState(() {});
                    },
                  ),
                );
              }
            },
          );
        } else {
          // Se não há dados no stream, o utilizador está deslogado
          return const LoginScreen();
        }
      },
    );
  }
}
