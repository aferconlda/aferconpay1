
import 'package:afercon_pay/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationIconWithBadge extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const NotificationIconWithBadge({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<NotificationIconWithBadge> createState() => _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true); // Faz a animação repetir (piscar)
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () {
            // Ao tocar, notificamos o provider que as notificações foram vistas
            if (provider.hasUnreadNotifications) {
              provider.markAsRead();
            }
            // E executamos a ação de navegação original
            widget.onTap();
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none, // Permite que o ponto saia fora da área do ícone
            children: [
              // O ícone principal
              Icon(widget.icon, size: 28), // Tamanho base do ícone

              // O ponto vermelho a piscar (só aparece se houver notificações)
              if (provider.hasUnreadNotifications)
                Positioned(
                  top: -2,
                  right: -2,
                  child: FadeTransition(
                    opacity: _animationController,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red, // <-- COR ALTERADA PARA VERMELHO
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
