import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'notifications_overlay.dart';
import '../../core/utils/responsive.dart';

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
      padding: EdgeInsets.only(
        left: Responsive.getResponsiveSpacing(
          context,
          mobile: 8,
          tablet: 9,
          desktop: 10,
        ),
        right: Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 15,
        ),
        top: Responsive.getResponsiveSpacing(
          context,
          mobile: 15,
          tablet: 18,
          desktop: 20,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/Casa.png',
            height: Responsive.getResponsiveFontSize(
              context,
              mobile: 45,
              tablet: 47,
              desktop: 50,
            ),
          ),
          Image.asset(
            'assets/images/obix.png',
            height: Responsive.getResponsiveFontSize(
              context,
              mobile: 45,
              tablet: 47,
              desktop: 50,
            ),
          ),
          GestureDetector(
            onTap: () => _openNotifications(context),
            child: ValueListenableBuilder<int>(
              valueListenable: notificationService.unreadCount,
              builder: (context, unread, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/images/notificacion.png',
                      height: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 36,
                        tablet: 38,
                        desktop: 40,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(
                            Responsive.getResponsiveSpacing(
                              context,
                              mobile: 3,
                              tablet: 3.5,
                              desktop: 4,
                            ),
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 9,
                                tablet: 9.5,
                                desktop: 10,
                              ),
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

