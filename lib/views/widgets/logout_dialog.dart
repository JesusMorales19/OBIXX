import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import 'custom_notification.dart';
import '../../core/utils/responsive.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      barrierDismissible: true, // se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // fondo transparente
          insetPadding: EdgeInsets.symmetric(
            horizontal: Responsive.getResponsiveSpacing(
              context,
              mobile: 20,
              tablet: 25,
              desktop: 30,
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(
              Responsive.getResponsiveSpacing(
                context,
                mobile: 18,
                tablet: 21,
                desktop: 24,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de advertencia
                Container(
                  padding: EdgeInsets.all(
                    Responsive.getResponsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.orange,
                    size: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 30,
                      tablet: 33,
                      desktop: 36,
                    ),
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),

                // Título
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 19,
                      desktop: 20,
                    ),
                    color: const Color(0xFF1F4E79),
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 11,
                    desktop: 12,
                  ),
                ),

                // Mensaje
                Text(
                  '¿Estás seguro de que quieres cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                ),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancelar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          vertical: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 10,
                            tablet: 11,
                            desktop: 12,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),

                    // Confirmar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          vertical: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 10,
                            tablet: 11,
                            desktop: 12,
                          ),
                        ),
                        elevation: 6,
                        shadowColor: Colors.orangeAccent,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await StorageService.clearSession();
                        await NotificationService.instance.clearSession();
                        if (context.mounted) {
                          CustomNotification.showSuccess(
                            context,
                            'Cierre de sesión exitoso.',
                          );
                        }
                        onConfirm();
                      },
                      child: Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
