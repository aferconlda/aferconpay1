import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/main_navigation_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';

class HomeRouterScreen extends StatefulWidget {
  const HomeRouterScreen({super.key});

  @override
  State<HomeRouterScreen> createState() => _HomeRouterScreenState();
}

class _HomeRouterScreenState extends State<HomeRouterScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<UserModel?> _loadUser() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      return await _firestoreService.getUser(user.uid);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Ocorreu um erro ao carregar os seus dados!')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // Isto pode acontecer se o utilizador for deslogado. 
          // Idealmente, a app navegaria de volta para o ecrã de login.
          return const Scaffold(
            body: Center(child: Text('Utilizador não autenticado!')),
          );
        }

        // Com base no UserModel, poderia haver lógica de roteamento aqui.
        // Por agora, todos os utilizadores vão para a tela principal.
        return const MainNavigationScreen();
      },
    );
  }
}
