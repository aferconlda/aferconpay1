
import 'package:afercon_pay/providers/notification_provider.dart';
import 'package:afercon_pay/screens/notifications/notifications_screen.dart';
import 'package:afercon_pay/widgets/blinking_dot.dart'; // Importa o widget do ponto a piscar
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlinkingNotificationIcon extends StatelessWidget {
  const BlinkingNotificationIcon({super.key});

  void _onIconPressed(BuildContext context) {
    // Ao clicar, marca as notificações como lidas
    context.read<NotificationProvider>().markAsRead();

    // E navega para o ecrã de notificações
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const NotificationsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // O Consumer garante que o widget se reconstrói quando o estado das notificações muda
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              // O ícone do sino
              const Icon(Icons.notifications_outlined),

              // Se houver notificações não lidas, mostra o ponto a piscar
              if (provider.hasUnreadNotifications)
                Positioned(
                  top: 0, // Ajuste para a sua preferência visual
                  right: 0, // Ajuste para a sua preferência visual
                  child: BlinkingDot(
                    color: Colors.red, // REPARADO: A cor agora é vermelha
                    size: 10.0,          // REPARADO: Usa o widget BlinkingDot
                  ),
                ),
            ],
          ),
          onPressed: () => _onIconPressed(context),
        );
      },
    );
  }
}
