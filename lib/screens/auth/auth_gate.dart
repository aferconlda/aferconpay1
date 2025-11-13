
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/authentication/login_screen.dart';
import 'package:afercon_pay/screens/authentication/verify_email_screen.dart';
import 'package:afercon_pay/screens/home/home_router_screen.dart';
import 'package:afercon_pay/screens/security/pin_setup_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/inactivity_detector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;

          if (!user.emailVerified) {
            return const VerifyEmailScreen();
          }

          // FutureBuilder is used here to handle the async operation of fetching user data
          return FutureBuilder<UserModel?>(
            future: firestoreService.getUser(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error loading your data.'),
                        ElevatedButton(
                          onPressed: () => authService.signOut(),
                          child: const Text('Try Again'),
                        )
                      ],
                    ),
                  ),
                );
              }

              final userModel = userSnapshot.data!;

              // Navigate based on whether the user has a transaction PIN
              if (userModel.hasTransactionPin) {
                return const InactivityDetector(
                  child: HomeRouterScreen(),
                );
              } else {
                return PopScope(
                   canPop: false,
                  child: PinSetupScreen(
                    onPinSet: () {
                     // Call setState to rebuild the AuthGate
                      setState(() {});
                    },
                  ),
                );
              }
            },
          );
        } else {
          // If there is no user data, show the login screen
          return const LoginScreen();
        }
      },
    );
  }
}
