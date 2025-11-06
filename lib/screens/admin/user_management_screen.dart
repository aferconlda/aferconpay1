import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // REFACTOR: State variable for the Stream
  late Stream<List<UserModel>> _usersStream;

  @override
  void initState() {
    super.initState();
    // REFACTOR: Initialize stream in initState
    _usersStream = _firestoreService.getAllUsersStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Gestão de Utilizadores')),
      body: StreamBuilder<List<UserModel>>(
        // REFACTOR: Use stream from state variable
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final users = snapshot.data;
          if (users == null || users.isEmpty) {
            return const Center(child: Text('Nenhum utilizador encontrado.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        title: Text(user.displayName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.email ?? 'N/A'),
        trailing: Chip(
          label: Text(
            user.role.toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
          backgroundColor: _getRoleColor(user.role),
        ),
        onTap: () => _showChangeRoleDialog(user),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade700;
      case 'cashier':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _showChangeRoleDialog(UserModel user) async {
    final availableRoles = ['client', 'cashier', 'admin'];

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alterar Função de ${user.displayName}'),
          content: DropdownButton<String>(
            value: user.role,
            isExpanded: true,
            items: availableRoles.map((String role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role.toUpperCase()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                Navigator.of(context).pop(newValue);
              }
            },
          ),
           actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (newRole != null && newRole != user.role) {
      try {
        await _firestoreService.updateUserRole(user.uid, newRole);
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Função de ${user.displayName} atualizada para ${newRole.toUpperCase()}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar função: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
