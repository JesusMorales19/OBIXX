import 'package:flutter/material.dart';
import '../views/widgets/custom_notification.dart';

/// Helper para operaciones seguras con BuildContext
class ContextHelper {
  /// Ejecuta una función solo si el contexto está montado
  static void safeCall(BuildContext? context, VoidCallback callback) {
    if (context != null && context.mounted) {
      callback();
    }
  }

  /// Ejecuta una función async solo si el contexto está montado
  static Future<T?> safeCallAsync<T>(
    BuildContext? context,
    Future<T> Function() callback,
  ) async {
    if (context != null && context.mounted) {
      return await callback();
    }
    return null;
  }

  /// Muestra una notificación de error solo si el contexto está montado
  static void safeShowError(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      CustomNotification.showError(context, message);
    }
  }

  /// Muestra una notificación de éxito solo si el contexto está montado
  static void safeShowSuccess(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      CustomNotification.showSuccess(context, message);
    }
  }

  /// Muestra una notificación de info solo si el contexto está montado
  static void safeShowInfo(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      CustomNotification.showInfo(context, message);
    }
  }

  /// Cierra el diálogo/indicador de carga solo si el contexto está montado
  static void safePop(BuildContext? context) {
    if (context != null && context.mounted) {
      Navigator.pop(context);
    }
  }

  /// Navega solo si el contexto está montado
  static void safeNavigate(
    BuildContext? context,
    void Function(BuildContext) navigate,
  ) {
    if (context != null && context.mounted) {
      navigate(context);
    }
  }

  /// Navega y elimina todas las rutas anteriores solo si el contexto está montado
  static void safeNavigateAndRemoveUntil(
    BuildContext? context,
    Widget destination,
  ) {
    if (context != null && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => destination),
        (route) => false,
      );
    }
  }
}

