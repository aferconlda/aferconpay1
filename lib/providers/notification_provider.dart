import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A mesma chave usada no notification_service
const String kUnreadNotificationFlag = 'has_unread_notifications';

class NotificationProvider with ChangeNotifier {
  bool _hasUnreadNotifications = false;

  bool get hasUnreadNotifications => _hasUnreadNotifications;

  NotificationProvider() {
    // Verifica o estado inicial ao ser criado
    checkInitialStatus();
  }

  /// Verifica se a flag de notificação não lida foi definida (por um background handler)
  Future<void> checkInitialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Se a flag for verdadeira, atualiza o estado da UI
    if (prefs.getBool(kUnreadNotificationFlag) ?? false) {
      setUnreadStatus(true);
    }
  }

  /// Define o estado e notifica os ouvintes. Não atualiza o SharedPreferences aqui.
  void setUnreadStatus(bool hasUnread) {
    if (_hasUnreadNotifications != hasUnread) {
      _hasUnreadNotifications = hasUnread;
      notifyListeners();
    }
  }

  /// A ser chamado pela UI quando o utilizador vê as notificações.
  Future<void> markAsRead() async {
    // Limpa a flag no armazenamento local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kUnreadNotificationFlag, false);

    // Atualiza o estado na UI
    setUnreadStatus(false);
  }
}
