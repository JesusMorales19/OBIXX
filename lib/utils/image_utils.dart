import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Solicita permisos de cámara y galería
  static Future<bool> solicitarPermisos() async {
    // Solicitar permiso de cámara
    final cameraStatus = await Permission.camera.request();
    
    // Solicitar permiso de galería
    // Para Android 13+ (API 33+) usar photos, para anteriores usar storage
    // Para iOS usar photos
    Permission storagePermission = Permission.photos;
    
    final storageStatus = await storagePermission.request();

    // Verificar si ambos permisos fueron concedidos
    final cameraGranted = cameraStatus.isGranted || cameraStatus.isLimited;
    final storageGranted = storageStatus.isGranted || storageStatus.isLimited;

    // Si el permiso de galería fue denegado, intentar con storage (Android antiguo)
    if (!storageGranted && Platform.isAndroid) {
      final storageStatusAlt = await Permission.storage.request();
      final storageGrantedAlt = storageStatusAlt.isGranted || storageStatusAlt.isLimited;
      return cameraGranted && storageGrantedAlt;
    }

    return cameraGranted && storageGranted;
  }

  /// Verifica si los permisos están concedidos
  static Future<bool> verificarPermisos() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    final cameraOk = cameraStatus.isGranted || cameraStatus.isLimited;
    // Verificar photos (Android 13+) o storage (Android anterior) o photos (iOS)
    final storageOk = photosStatus.isGranted || 
                      photosStatus.isLimited || 
                      storageStatus.isGranted || 
                      storageStatus.isLimited;

    return cameraOk && storageOk;
  }

  /// Abre la configuración de la app si los permisos fueron denegados permanentemente
  static Future<void> abrirConfiguracion() async {
    await openAppSettings();
  }

  /// Toma una foto con la cámara
  static Future<XFile?> tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Calidad reducida para archivos más pequeños (0-100)
        maxWidth: 800, // Redimensionar a máximo 800px de ancho
        maxHeight: 800, // Redimensionar a máximo 800px de alto
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  /// Selecciona una imagen de la galería
  static Future<XFile?> seleccionarDeGaleria() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Calidad reducida para archivos más pequeños
        maxWidth: 800, // Redimensionar a máximo 800px de ancho
        maxHeight: 800, // Redimensionar a máximo 800px de alto
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  /// Convierte un archivo de imagen a Base64
  static Future<String?> imagenABase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      return null;
    }
  }

  /// Convierte un archivo de imagen a Base64 con prefijo data URI
  static Future<String?> imagenABase64DataURI(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Determinar el tipo MIME basado en la extensión
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }
      
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      return null;
    }
  }

  /// Convierte Base64 a bytes (útil para guardar en base de datos como BLOB)
  static List<int> base64ABytes(String base64String) {
    return base64Decode(base64String);
  }
}

