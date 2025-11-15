import '../views/widgets/custom_notification.dart';
import 'navigation_service.dart';

/// Wrapper para llamadas API con manejo seguro de errores
class ApiWrapper {
  /// Ejecuta una llamada API de forma segura con manejo de errores
  /// 
  /// Retorna el resultado si es exitoso, null si hay error
  /// Muestra notificación de error automáticamente
  static Future<T?> safeCall<T>({
    required Future<T> Function() call,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      return await call();
    } catch (e) {
      if (showError) {
        final context = NavigationService.context;
        if (context != null && context.mounted) {
          CustomNotification.showError(
            context,
            errorMessage ?? 'Error: ${e.toString()}',
          );
        }
      }
      return null;
    }
  }

  /// Ejecuta una llamada API y retorna un Map con success/error
  static Future<Map<String, dynamic>> safeCallWithResult<T>({
    required Future<T> Function() call,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      final result = await call();
      return {
        'success': true,
        'data': result,
      };
    } catch (e) {
      if (showError) {
        final context = NavigationService.context;
        if (context != null && context.mounted) {
          CustomNotification.showError(
            context,
            errorMessage ?? 'Error: ${e.toString()}',
          );
        }
      }
      return {
        'success': false,
        'error': errorMessage ?? e.toString(),
      };
    }
  }

  /// Ejecuta múltiples llamadas API en paralelo de forma segura
  static Future<List<T?>> safeCallMultiple<T>({
    required List<Future<T> Function()> calls,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      final futures = calls.map((call) => call());
      return await Future.wait(futures);
    } catch (e) {
      if (showError) {
        final context = NavigationService.context;
        if (context != null && context.mounted) {
          CustomNotification.showError(
            context,
            errorMessage ?? 'Error: ${e.toString()}',
          );
        }
      }
      return List.filled(calls.length, null);
    }
  }

  /// Ejecuta múltiples llamadas API en paralelo con manejo de errores individual
  /// Retorna una lista de resultados, donde cada resultado puede ser null si falló
  static Future<List<T?>> safeCallMultipleWithIndividualErrors<T>({
    required List<Future<T> Function()> calls,
    String? generalErrorMessage,
    bool showError = true,
  }) async {
    final results = <T?>[];
    for (int i = 0; i < calls.length; i++) {
      try {
        final result = await calls[i]();
        results.add(result);
      } catch (e) {
        results.add(null);
        if (showError) {
          final context = NavigationService.context;
          if (context != null && context.mounted) {
            CustomNotification.showError(
              context,
              generalErrorMessage ?? 'Error en operación ${i + 1}: ${e.toString()}',
            );
          }
        }
      }
    }
    return results;
  }
}

