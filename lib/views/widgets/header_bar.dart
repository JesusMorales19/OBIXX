import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'notifications_overlay.dart';

class HeaderBar extends StatelessWidget {
  final String tipoUsuario;

  const HeaderBar({super.key, required this.tipoUsuario});

  Future<void> _openNotifications(BuildContext context) async {
    await showNotificationsOverlay(context: context, tipoUsuario: tipoUsuario);
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService.instance;

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 15, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/Casa.png', height: 50),
          Image.asset('assets/images/obix.png', height: 50),
          GestureDetector(
            onTap: () => _openNotifications(context),
            child: ValueListenableBuilder<int>(
              valueListenable: notificationService.unreadCount,
              builder: (context, unread, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset('assets/images/notificacion.png', height: 40),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

