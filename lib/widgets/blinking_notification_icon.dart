
import 'package:afercon_pay/providers/notification_provider.dart';
import 'package:afercon_pay/screens/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlinkingNotificationIcon extends StatefulWidget {
  const BlinkingNotificationIcon({super.key});

  @override
  State<BlinkingNotificationIcon> createState() => _BlinkingNotificationIconState();
}

class _BlinkingNotificationIconState extends State<BlinkingNotificationIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onIconPressed(BuildContext context) {
    // Mark notifications as read
    context.read<NotificationProvider>().markAsRead();

    // Navigate to the notifications screen
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const NotificationsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (provider.hasUnreadNotifications)
                Positioned(
                  top: -4,
                  right: -4,
                  child: FadeTransition(
                    opacity: _animationController,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
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
