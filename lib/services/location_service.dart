import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Solicita permisos de ubicación
  static Future<bool> solicitarPermisoUbicacion() async {
    // Verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Solicitar permiso de ubicación
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permisos denegados permanentemente
      return false;
    }

    return true;
  }

  /// Obtiene la ubicación actual del dispositivo
  static Future<Position?> obtenerUbicacionActual() async {
    try {
      // Verificar permisos
      final tienePermiso = await solicitarPermisoUbicacion();
      if (!tienePermiso) {
        return null;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error al obtener ubicación: $e');
      return null;
    }
  }

  /// Abre la configuración de la app para habilitar ubicación
  static Future<void> abrirConfiguracion() async {
    await openAppSettings();
  }

  /// Verifica si los permisos de ubicación están concedidos
  static Future<bool> tienePermisoUbicacion() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Calcula la distancia entre dos puntos en kilómetros
  static double calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convertir a km
  }
}

