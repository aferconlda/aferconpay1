import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/admin/verification_detail_screen.dart'; // Importar o ecrã de detalhes
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Stream que obtém os utilizadores com KYC pendente.
  Stream<List<UserModel>> _getPendingUsersStream() {
    return _firestoreService.getUsersByKycStatusStream(KycStatus.pending);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Verificações Pendentes')),
      body: StreamBuilder<List<UserModel>>(
        stream: _getPendingUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar utilizadores: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum pedido de verificação pendente.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              // Cada item da lista é agora um cartão clicável.
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        title: Text(user.displayName ?? 'N/A', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        subtitle: Text(user.email ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium),
        trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        // Ao tocar, navega para o ecrã de detalhes, passando o utilizador.
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerificationDetailScreen(user: user),
            ),
          );
        },
      ),
    );
  }
}
