import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _baseUrlKey = 'server_base_url';
  
  // URL por defecto del servidor
  static const String defaultUrl = 'https://obix.onrender.com/api';

  /// Obtiene la URL base del servidor
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    
    // Si hay una URL guardada, usarla; si no, usar la por defecto
    return savedUrl ?? defaultUrl;
  }

  /// Guarda la URL base del servidor
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  /// Limpia la configuración guardada
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
  }
}

