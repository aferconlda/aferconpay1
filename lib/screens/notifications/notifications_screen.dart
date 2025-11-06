import 'package:afercon_pay/models/notification_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  Stream<List<NotificationModel>>? _notificationsStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          _notificationsStream = _firestoreService.getNotificationsStream(authUser.uid);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    if (_currentUser != null && !notification.read) {
      _firestoreService.markNotificationAsRead(
          _currentUser!.uid, notification.id);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentUser != null) {
      await _firestoreService.markAllNotificationsAsRead(_currentUser!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Todas as notificações foram marcadas como lidas.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: Text('Notificações')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: Text('Notificações')),
        body: Center(
          child: Text('Utilizador não autenticado.'),
        ),
      );
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            appBar: CustomAppBar(title: Text('Notificações')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: const CustomAppBar(title: Text('Notificações')),
            body: Center(child: Text('Erro: ${snapshot.error.toString()}')),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: const CustomAppBar(title: Text('Notificações')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80,
                      color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Nenhuma notificação ainda',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        final notifications = snapshot.data!;
        final unreadCount = notifications.where((n) => !n.read).length;

        return Scaffold(
          appBar: CustomAppBar(
            title: const Text('Notificações'),
            actions: [
              if (unreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Marcar todas como lidas',
                  onPressed: _markAllAsRead,
                ),
            ],
          ),
          body: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification.read;

              return Card(
                elevation: 2,
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  onTap: () => _onNotificationTap(notification),
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey[300]
                        : Theme.of(context).primaryColor,
                    child: Icon(
                      isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: isRead ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM, yyyy HH:mm', 'pt_AO')
                            .format(notification.date.toDate()),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
