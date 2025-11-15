# 📱 Permisos Configurados en la Aplicación

## ✅ Permisos Agregados

### Android (`android/app/src/main/AndroidManifest.xml`)

1. **Cámara**
   - `android.permission.CAMERA` - Para tomar fotos

2. **Galería/Archivos**
   - `android.permission.READ_EXTERNAL_STORAGE` - Para leer imágenes
   - `android.permission.WRITE_EXTERNAL_STORAGE` - Para guardar (Android 12 y anteriores)
   - `android.permission.READ_MEDIA_IMAGES` - Para Android 13+ (API 33+)

3. **Ubicación**
   - `android.permission.ACCESS_FINE_LOCATION` - Ubicación precisa (GPS)
   - `android.permission.ACCESS_COARSE_LOCATION` - Ubicación aproximada (red/WiFi)
   - `android.permission.ACCESS_BACKGROUND_LOCATION` - Ubicación en segundo plano

4. **Internet**
   - `android.permission.INTERNET` - Para conexiones HTTP

### iOS (`ios/Runner/Info.plist`)

1. **Cámara**
   - `NSCameraUsageDescription` - Descripción para acceso a cámara

2. **Galería/Fotos**
   - `NSPhotoLibraryUsageDescription` - Descripción para leer fotos
   - `NSPhotoLibraryAddUsageDescription` - Descripción para guardar fotos

3. **Ubicación**
   - `NSLocationWhenInUseUsageDescription` - Ubicación cuando la app está en uso
   - `NSLocationAlwaysAndWhenInUseUsageDescription` - Ubicación siempre (incluye segundo plano)
   - `NSLocationAlwaysUsageDescription` - Ubicación en segundo plano

## 📦 Paquetes Agregados

### `pubspec.yaml`

1. **permission_handler: ^11.3.1**
   - Para solicitar y verificar permisos en tiempo de ejecución

2. **geolocator: ^13.0.1**
   - Para obtener la ubicación del dispositivo

## 🚀 Cómo Usar los Permisos en el Código

### Ejemplo: Solicitar Permiso de Cámara

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> solicitarPermisoCamara() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    // El permiso fue concedido, puedes usar la cámara
  } else if (status.isDenied) {
    // El permiso fue denegado
  } else if (status.isPermanentlyDenied) {
    // El permiso fue denegado permanentemente, abrir configuración
    await openAppSettings();
  }
}
```

### Ejemplo: Solicitar Permiso de Ubicación

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

Future<Position?> obtenerUbicacion() async {
  // Verificar si el servicio de ubicación está habilitado
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }

  // Verificar permisos
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return null;
  }

  // Obtener ubicación actual
  return await Geolocator.getCurrentPosition();
}
```

### Ejemplo: Verificar Permiso de Galería

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> tienePermisoGaleria() async {
  if (await Permission.photos.isGranted) {
    return true;
  }
  
  final status = await Permission.photos.request();
  return status.isGranted;
}
```

## 📝 Notas Importantes

1. **Android 13+ (API 33+)**: 
   - Ya no se usa `WRITE_EXTERNAL_STORAGE`
   - Se usa `READ_MEDIA_IMAGES` para leer imágenes

2. **iOS**: 
   - Todas las descripciones de permisos son obligatorias
   - El usuario verá estos mensajes cuando se solicite el permiso

3. **Ubicación en Segundo Plano**:
   - Requiere permisos adicionales y configuración especial
   - Úsalo solo si realmente lo necesitas

4. **Instalación de Paquetes**:
   ```bash
   flutter pub get
   ```

## 🔍 Verificar Permisos

Puedes verificar si un permiso está concedido:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> verificarPermiso(Permission permiso) async {
  final status = await permiso.status;
  return status.isGranted;
}
```

## 📍 Archivos Modificados

- ✅ `android/app/src/main/AndroidManifest.xml`
- ✅ `ios/Runner/Info.plist`
- ✅ `pubspec.yaml`

