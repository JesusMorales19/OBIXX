import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final ValueNotifier<Map<String, dynamic>?> userNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  // Guardar token JWT
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Obtener token JWT
  static Future<String?> getToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      return token;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Eliminar token JWT
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Guardar datos del usuario
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final data = jsonEncode(user);
    await _secureStorage.write(key: _userKey, value: data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    userNotifier.value = Map<String, dynamic>.from(user);
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUser() async {
    final stored = await _secureStorage.read(key: _userKey);
    final dataString = stored ?? await _readUserFromPrefs();
    if (dataString == null) {
      userNotifier.value = null;
      return null;
    }
    try {
      final map = jsonDecode(dataString) as Map<String, dynamic>;
      if (!mapEquals(userNotifier.value, map)) {
        userNotifier.value = Map<String, dynamic>.from(map);
      }
      return map;
    } catch (_) {
      userNotifier.value = null;
      return null;
    }
  }

  static Future<void> mergeUser(Map<String, dynamic> updates) async {
    final current = await getUser();
    if (current == null) {
      return;
    }

    final updated = Map<String, dynamic>.from(current)..addAll(updates);
    await saveUser(updated);
  }

  static Future<String?> _readUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  // Eliminar datos del usuario
  static Future<void> deleteUser() async {
    await _secureStorage.delete(key: _userKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    userNotifier.value = null;
  }

  // Limpiar toda la sesión
  static Future<void> clearSession() async {
    await Future.wait([deleteToken(), deleteUser()]);
    userNotifier.value = null;
  }

  // Verificar si hay una sesión activa
  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

