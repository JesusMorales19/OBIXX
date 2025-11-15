import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import 'custom_notification.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      barrierDismissible: true, // se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // fondo transparente
          child: Container(
            padding: const EdgeInsets.all(24),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.orange,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1F4E79),
                  ),
                ),
                const SizedBox(height: 12),

                // Mensaje
                const Text(
                  '¿Estás seguro de que quieres cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 16),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
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
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 16),
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
