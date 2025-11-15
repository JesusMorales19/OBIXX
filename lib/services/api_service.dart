import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contratista_model.dart';
import '../models/trabajador_model.dart';
import '../models/trabajo_largo_model.dart';
import '../models/trabajo_corto_model.dart'; // Added import for TrabajoCortoModel
import '../models/asignacion_trabajo_model.dart';
import 'config_service.dart';

class ApiService {
  // La URL base se obtiene de ConfigService
  static Future<String> get baseUrl async => await ConfigService.getBaseUrl();

  // Función auxiliar para normalizar la URL base
  static String _normalizeBaseUrl(String urlBase) {
    // Asegurar que la URL base termine en /api
    if (!urlBase.endsWith('/api')) {
      if (urlBase.endsWith('/')) {
        urlBase = '${urlBase}api';
      } else {
        urlBase = '$urlBase/api';
      }
    }
    return urlBase;
  }

  // Función auxiliar para hacer peticiones GET
  static Future<Map<String, dynamic>> _getRequest(
    String endpoint,
    Map<String, String> params,
  ) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      
      // Asegurar que el endpoint comience con /
      final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      
      // Construir URL con parámetros query
      final uri = Uri.parse('$urlBase$normalizedEndpoint').replace(queryParameters: params);
      
      print('GET URL Completa: $uri');
      print('Parámetros: $params');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('GET Respuesta - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error en _getRequest: $e');
      return {
        'success': false,
        'error': 'Error de red: ${e.toString()}',
      };
    }
  }

  // Función auxiliar para hacer peticiones POST/PUT
  static Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    bool isPut = false,
  }) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      
      // Asegurar que el endpoint comience con /
      final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final url = Uri.parse('$urlBase$normalizedEndpoint');
      
      print('URL Base: $urlBase');
      print('Endpoint: $normalizedEndpoint');
      print('URL Completa: $url');
      print('Datos enviados: ${jsonEncode(body)}');
      
      final response = isPut 
        ? await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado. Verifica que el servidor esté corriendo.');
            },
          )
        : await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica que el servidor esté corriendo.');
        },
      );

      print('Respuesta recibida - Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
        final responseData = jsonDecode(response.body);
        return {
            'success': responseData['success'] ?? true,
          'data': responseData,
            'error': responseData['error'],
          };
        } catch (e) {
          // Si la respuesta no es JSON válido
          return {
            'success': false,
            'error': 'El servidor respondió con un formato inesperado. Verifica que el servidor backend esté corriendo correctamente.',
        };
        }
      } else {
        // Intentar parsear como JSON, pero si falla, mostrar el error HTTP
        try {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? responseData['message'] ?? 'Error desconocido',
        };
        } catch (e) {
          // Si la respuesta es HTML (como un 404 de Flask/Express)
          if (response.body.contains('<!doctype html>') || response.body.contains('<html')) {
            return {
              'success': false,
              'error': 'Error ${response.statusCode}: La ruta no fue encontrada en el servidor.\n\n'
                  'Verifica que:\n'
                  '1. El servidor backend esté corriendo (cd backend && npm start)\n'
                  '2. La URL sea correcta: $url\n'
                  '3. La ruta /api/register/contratista exista en el servidor',
            };
          }
          return {
            'success': false,
            'error': 'Error ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error de conexión: $e');
      String errorMessage = 'Error de conexión';
      
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to fetch') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'No se pudo conectar al servidor.\n\n'
            'Verifica que:\n'
            '1. El servidor backend esté corriendo (cd backend && npm start)\n'
            '2. La URL sea correcta para tu plataforma\n'
            '3. No haya problemas de red o firewall';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Tiempo de espera agotado.\n\n'
            'El servidor no respondió a tiempo.\n'
            'Verifica que el servidor esté corriendo.';
      } else {
        errorMessage = 'Error: ${e.toString()}\n\n'
            'Verifica que el servidor backend esté corriendo en el puerto 3000.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  static Future<Map<String, dynamic>> _deleteRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      final normalizedEndpoint =
          endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final url = Uri.parse('$urlBase$normalizedEndpoint');

      final response = await http
          .delete(
            url,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Tiempo de espera agotado'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'error':
            'Error ${response.statusCode}: ${response.body.isEmpty ? 'sin respuesta' : response.body}',
      };
    } catch (error) {
      return {
        'success': false,
        'error': 'Error eliminando token: $error',
      };
    }
  }

  // Registrar contratista
  static Future<Map<String, dynamic>> registrarContratista(
    ContratistaModel contratista,
  ) async {
    return await _postRequest('/register/contratista', contratista.toJson());
  }

  // Registrar trabajador
  static Future<Map<String, dynamic>> registrarTrabajador(
    TrabajadorModel trabajador,
  ) async {
    return await _postRequest('/register/trabajador', trabajador.toJson());
  }

  // Login - permite usar email o username
  // El backend detecta automáticamente el tipo de usuario
  static Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    return await _postRequest('/auth/login', {
      'emailOrUsername': emailOrUsername,
      'password': password,
    });
  }

  // Verificar token JWT
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      final url = Uri.parse('$urlBase/auth/verify');
      
      print('URL Base: $urlBase');
      print('Verificando token: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('Respuesta verificación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Error al verificar token',
        };
      }
    } catch (e) {
      print('Error al verificar token: $e');
      return {
        'success': false,
        'error': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener categorías
  static Future<Map<String, dynamic>> getCategorias() async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      final url = Uri.parse('$urlBase/categorias');
      
      print('URL Base: $urlBase');
      print('Obteniendo categorías desde: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('Respuesta categorías - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? [],
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Error al obtener categorías',
        };
      }
    } catch (e) {
      print('Error al obtener categorías: $e');
      return {
        'success': false,
        'error': 'Error de conexión: ${e.toString()}',
        'data': [],
      };
    }
  }

  /// Agregar trabajador a favoritos
  static Future<Map<String, dynamic>> agregarFavorito(
    String emailContratista,
    String emailTrabajador,
  ) async {
    return await _postRequest('/favoritos/agregar', {
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
    });
  }

  /// Quitar trabajador de favoritos
  static Future<Map<String, dynamic>> quitarFavorito(
    String emailContratista,
    String emailTrabajador,
  ) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);

      final response = await http.delete(
        Uri.parse('$urlBase/favoritos/quitar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailContratista': emailContratista,
          'emailTrabajador': emailTrabajador,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Error al quitar favorito: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de red: $e',
      };
    }
  }

  /// Verificar si un trabajador está en favoritos
  static Future<Map<String, dynamic>> verificarFavorito(
    String emailContratista,
    String emailTrabajador,
  ) async {
    return await _getRequest('/favoritos/verificar', {
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
    });
  }

  /// Listar todos los favoritos de un contratista
  static Future<Map<String, dynamic>> listarFavoritos(
    String emailContratista,
  ) async {
    return await _getRequest('/favoritos/listar', {
      'emailContratista': emailContratista,
    });
  }

  // ========== TRABAJOS DE LARGO PLAZO ==========

  /// Registrar un nuevo trabajo de largo plazo
  static Future<Map<String, dynamic>> registrarTrabajoLargoPlazo(
    TrabajoLargoModel trabajo,
  ) async {
    return await _postRequest(
      '/trabajos-largo-plazo/registrar',
      trabajo.toJsonForCreate(),
    );
  }

  /// Obtener trabajos de largo plazo de un contratista
  static Future<Map<String, dynamic>> obtenerTrabajosContratista(
    String emailContratista,
  ) async {
    return await _getRequest('/trabajos-largo-plazo/contratista', {
      'emailContratista': emailContratista,
    });
  }

  /// Buscar trabajos cercanos (para trabajadores)
  static Future<Map<String, dynamic>> buscarTrabajosCercanos(
    String emailTrabajador, {
    int radio = 500,
  }) async {
    return await _getRequest('/trabajos-largo-plazo/cercanos', {
      'emailTrabajador': emailTrabajador,
      'radio': radio.toString(),
    });
  }

  // ========== TRABAJOS DE CORTO PLAZO ==========

  /// Registrar trabajo corto plazo con imágenes en Base64
  static Future<Map<String, dynamic>> registrarTrabajoCortoPlazo(
    TrabajoCortoModel trabajo,
  ) async {
    return await _postRequest(
      '/trabajos-corto-plazo/registrar',
      trabajo.toJsonForCreate(),
    );
  }

  /// Trabajos corto plazo del contratista
  static Future<Map<String, dynamic>> obtenerTrabajosCortoContratista(
    String emailContratista,
  ) async {
    return await _getRequest('/trabajos-corto-plazo/contratista', {
      'emailContratista': emailContratista,
    });
  }

  /// Trabajos corto plazo cercanos al trabajador
  static Future<Map<String, dynamic>> buscarTrabajosCortoCercanos(
    String emailTrabajador, {
    int radio = 500,
  }) async {
    return await _getRequest('/trabajos-corto-plazo/cercanos', {
      'emailTrabajador': emailTrabajador,
      'radio': radio.toString(),
    });
  }

  static Future<Map<String, dynamic>> asignarTrabajo(
    AsignacionTrabajoModel asignacion,
  ) async {
    return await _postRequest('/asignaciones/asignar', asignacion.toJsonForCreate());
  }

  static Future<Map<String, dynamic>> aplicarASolicitud({
    required String emailTrabajador,
    required String tipoTrabajo,
    required int idTrabajo,
  }) async {
    return await _postRequest('/solicitudes/aplicar', {
      'emailTrabajador': emailTrabajador,
      'tipoTrabajo': tipoTrabajo,
      'idTrabajo': idTrabajo,
    });
  }

  static Future<Map<String, dynamic>> obtenerSolicitudPendienteTrabajador(
    String emailTrabajador,
  ) async {
    return await _getRequest('/solicitudes/pendiente', {
      'emailTrabajador': emailTrabajador,
    });
  }

  static Future<Map<String, dynamic>> obtenerNumeroSolicitudesActivas(
    String emailTrabajador,
  ) async {
    return await _getRequest('/solicitudes/numero-activas', {
      'emailTrabajador': emailTrabajador,
    });
  }

  static Future<Map<String, dynamic>> obtenerSolicitudesActivasTrabajador(
    String emailTrabajador,
  ) async {
    return await _getRequest('/solicitudes/activas', {
      'emailTrabajador': emailTrabajador,
    });
  }

  static Future<Map<String, dynamic>> obtenerTrabajadoresAsignados({
    required String emailContratista,
    required String tipoTrabajo,
    required int idTrabajo,
  }) async {
    return await _getRequest('/asignaciones/trabajadores', {
      'emailContratista': emailContratista,
      'tipoTrabajo': tipoTrabajo,
      'idTrabajo': idTrabajo.toString(),
    });
  }

  static Future<Map<String, dynamic>> cancelarAsignacion({
    required String emailContratista,
    required String emailTrabajador,
    bool iniciadoPorTrabajador = false,
    bool skipDefaultNotification = false,
  }) async {
    final body = <String, dynamic>{
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
      'iniciadoPorTrabajador': iniciadoPorTrabajador,
    };
    if (skipDefaultNotification) {
      body['skipDefaultNotification'] = true;
    }
    return await _postRequest('/asignaciones/cancelar', body);
  }

  static Future<Map<String, dynamic>> obtenerTrabajoActualTrabajador(
    String emailTrabajador,
  ) async {
    return await _getRequest('/asignaciones/trabajador/actual', {
      'emailTrabajador': emailTrabajador,
    });
  }

  static Future<Map<String, dynamic>> registrarCalificacionTrabajador({
    required String emailContratista,
    required String emailTrabajador,
    required int idAsignacion,
    required int estrellas,
    String? resena,
  }) async {
    return await _postRequest('/calificaciones/registrar', {
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
      'idAsignacion': idAsignacion,
      'estrellas': estrellas,
      'resena': resena,
    });
  }

  static Future<Map<String, dynamic>> obtenerCalificacionesTrabajador(
    String emailTrabajador,
  ) async {
    return await _getRequest('/calificaciones/trabajador', {
      'emailTrabajador': emailTrabajador,
    });
  }

  static Future<Map<String, dynamic>> obtenerPerfilTrabajador(
    String emailTrabajador,
  ) async {
    return await _getRequest('/trabajadores/perfil', {
      'email': emailTrabajador,
    });
  }

  static Future<Map<String, dynamic>> finalizarTrabajo({
    required String emailContratista,
    required String tipoTrabajo,
    required int idTrabajo,
    required List<Map<String, dynamic>> calificaciones,
  }) async {
    return await _postRequest('/asignaciones/finalizar', {
      'emailContratista': emailContratista,
      'tipoTrabajo': tipoTrabajo,
      'idTrabajo': idTrabajo,
      'calificaciones': calificaciones,
    });
  }

  static Future<Map<String, dynamic>> registrarTokenDispositivo({
    required String email,
    required String tipoUsuario,
    required String token,
    String? plataforma,
  }) async {
    return await _postRequest('/notificaciones/token', {
      'email': email,
      'tipoUsuario': tipoUsuario,
      'token': token,
      'plataforma': plataforma,
    });
  }

  static Future<Map<String, dynamic>> eliminarTokenDispositivo(
    String token,
  ) async {
    return await _deleteRequest('/notificaciones/token', {
      'token': token,
    });
  }

  static Future<Map<String, dynamic>> obtenerNotificaciones({
    required String email,
    required String tipoUsuario,
  }) async {
    return await _getRequest('/notificaciones', {
      'email': email,
      'tipoUsuario': tipoUsuario,
    });
  }

  static Future<Map<String, dynamic>> marcarNotificacionesLeidas({
    required String email,
    required List<int> ids,
  }) async {
    return await _postRequest('/notificaciones/marcar-leidas', {
      'email': email,
      'ids': ids,
    });
  }

  static Future<Map<String, dynamic>> eliminarNotificaciones({
    required String email,
  }) async {
    return await _deleteRequest('/notificaciones', {
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> notificarInteresContratista({
    required String emailContratista,
    required String emailTrabajador,
    String? nombreContratista,
    String? nombreTrabajador,
    String? tipoTrabajo,
    int? idTrabajo,
  }) async {
    final body = <String, dynamic>{
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
      if (nombreContratista != null && nombreContratista.isNotEmpty)
        'nombreContratista': nombreContratista,
      if (nombreTrabajador != null && nombreTrabajador.isNotEmpty)
        'nombreTrabajador': nombreTrabajador,
      if (tipoTrabajo != null && tipoTrabajo.isNotEmpty) 'tipoTrabajo': tipoTrabajo,
      if (idTrabajo != null) 'idTrabajo': idTrabajo,
    };

    return await _postRequest('/notificaciones/interes-contratista', body);
  }

  static Future<Map<String, dynamic>> notificarCancelacionContratista({
    required String emailContratista,
    required String emailTrabajador,
    String? nombreContratista,
    String? tipoTrabajo,
    int? idTrabajo,
  }) async {
    final body = <String, dynamic>{
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
      if (nombreContratista != null && nombreContratista.isNotEmpty)
        'nombreContratista': nombreContratista,
      if (tipoTrabajo != null && tipoTrabajo.isNotEmpty) 'tipoTrabajo': tipoTrabajo,
      if (idTrabajo != null) 'idTrabajo': idTrabajo,
    };

    return await _postRequest('/notificaciones/cancelacion-contratista', body);
  }

  
  /// Actualiza la ubicación de un contratista
  static Future<Map<String, dynamic>> actualizarUbicacionContratista(
    String email,
    double latitud,
    double longitud,
  ) async {
    return await _postRequest('/ubicacion/contratista', {
      'email': email,
      'latitud': latitud,
      'longitud': longitud,
    }, isPut: true);
  }

  /// Actualiza la ubicación de un trabajador
  static Future<Map<String, dynamic>> actualizarUbicacionTrabajador(
    String email,
    double latitud,
    double longitud,
  ) async {
    return await _postRequest('/ubicacion/trabajador', {
      'email': email,
      'latitud': latitud,
      'longitud': longitud,
    }, isPut: true);
  }

  /// Busca trabajadores cercanos para un contratista (radio en km)
  /// Devuelve solo 1 trabajador por categoría (el más cercano)
  static Future<Map<String, dynamic>> buscarTrabajadoresCercanos(
    String email, {
    int radio = 500,
  }) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      final url = Uri.parse('$urlBase/ubicacion/trabajadores-cercanos?email=$email&radio=$radio');
      
      print('Buscando trabajadores cercanos: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Error al buscar trabajadores',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  /// Busca contratistas/trabajos cercanos para un trabajador (radio en km)
  static Future<Map<String, dynamic>> buscarContratistasCercanos(
    String email, {
    int radio = 500,
  }) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      final url = Uri.parse('$urlBase/ubicacion/contratistas-cercanos?email=$email&radio=$radio');
      
      print('Buscando contratistas cercanos: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Error al buscar contratistas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  /// Busca TODOS los trabajadores de una categoría específica cercanos al contratista
  /// Para la vista de "Ver más"
  static Future<Map<String, dynamic>> buscarTrabajadoresPorCategoria(
    String email,
    String categoria, {
    int radio = 500,
  }) async {
    try {
      var urlBase = await baseUrl;
      urlBase = _normalizeBaseUrl(urlBase);
      final url = Uri.parse('$urlBase/ubicacion/trabajadores-por-categoria?email=$email&categoria=$categoria&radio=$radio');
      
      print('Buscando trabajadores de categoría $categoria: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Error al buscar trabajadores',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  // Función auxiliar para hacer peticiones PUT
  static Future<Map<String, dynamic>> _putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await _postRequest(endpoint, body, isPut: true);
  }

  // Obtener perfil del contratista
  static Future<Map<String, dynamic>> obtenerPerfilContratista(
    String emailContratista,
  ) async {
    return await _getRequest('/contratistas/perfil', {
      'email': emailContratista,
    });
  }

  static Future<Map<String, dynamic>> actualizarPerfilContratista({
    required String emailActual,
    String? nuevoEmail,
    String? telefono,
    String? fotoPerfilBase64,
    String? passwordActual,
    String? passwordNueva,
  }) async {
    final Map<String, dynamic> payload = {
      'emailActual': emailActual,
    };

    if (nuevoEmail != null) payload['nuevoEmail'] = nuevoEmail;
    if (telefono != null) payload['telefono'] = telefono;
    if (fotoPerfilBase64 != null) {
      payload['fotoPerfilBase64'] = fotoPerfilBase64;
    }
    if (passwordNueva != null) payload['passwordNueva'] = passwordNueva;
    if (passwordActual != null) payload['passwordActual'] = passwordActual;

    return await _postRequest(
      '/contratistas/perfil',
      payload,
      isPut: true,
    );
  }

  static Future<Map<String, dynamic>> actualizarPerfilTrabajador({
    required String emailActual,
    String? nuevoEmail,
    String? telefono,
    String? descripcion,
    String? fotoPerfilBase64,
    String? passwordActual,
    String? passwordNueva,
  }) async {
    final Map<String, dynamic> payload = {
      'emailActual': emailActual,
    };

    if (nuevoEmail != null) payload['nuevoEmail'] = nuevoEmail;
    if (telefono != null) payload['telefono'] = telefono;
    if (descripcion != null) payload['descripcion'] = descripcion;
    if (fotoPerfilBase64 != null) payload['fotoPerfilBase64'] = fotoPerfilBase64;
    if (passwordNueva != null) payload['passwordNueva'] = passwordNueva;
    if (passwordActual != null) payload['passwordActual'] = passwordActual;

    return await _postRequest(
      '/trabajadores/perfil',
      payload,
      isPut: true,
    );
  }

  // ================================================
  // MÉTODOS PREMIUM
  // ================================================

  // Verificar si tiene premium activo
  static Future<Map<String, dynamic>> verificarPremium(String email) async {
    return await _getRequest('/premium/verificar', {'email': email});
  }

  // Activar suscripción premium
  static Future<Map<String, dynamic>> activarSuscripcion({
    required String emailContratista,
    required int idPlan,
    required bool guardarTarjeta,
    required bool autoRenovacion,
    Map<String, dynamic>? metodoPago,
  }) async {
    final payload = {
      'email_contratista': emailContratista,
      'id_plan': idPlan,
      'guardar_tarjeta': guardarTarjeta,
      'auto_renovacion': autoRenovacion,
    };
    if (metodoPago != null) {
      payload['metodo_pago'] = metodoPago;
    }
    return await _postRequest('/premium/activar', payload);
  }

  // Cancelar suscripción premium
  static Future<Map<String, dynamic>> cancelarSuscripcion({
    required String emailContratista,
  }) async {
    return await _postRequest('/premium/cancelar', {
      'email_contratista': emailContratista,
    });
  }

  // Obtener trabajos para administración
  static Future<Map<String, dynamic>> obtenerTrabajosAdministracion(String email) async {
    return await _getRequest('/premium/trabajos', {'email': email});
  }

  // Registrar presupuesto
  static Future<Map<String, dynamic>> registrarPresupuesto({
    required String emailContratista,
    required int idTrabajoLargo,
    required double presupuesto,
    String moneda = 'MXN',
  }) async {
    return await _postRequest('/premium/presupuesto', {
      'email_contratista': emailContratista,
      'id_trabajo_largo': idTrabajoLargo,
      'presupuesto': presupuesto,
      'moneda': moneda,
    });
  }

  // Registrar horas laborales
  static Future<Map<String, dynamic>> registrarHoras({
    required int idAsignacion,
    required String emailTrabajador,
    required String emailContratista,
    required String fecha,
    required double horas,
    double? minutos,
    String? nota,
  }) async {
    final payload = {
      'id_asignacion': idAsignacion,
      'email_trabajador': emailTrabajador,
      'email_contratista': emailContratista,
      'fecha': fecha,
      'horas': horas,
    };
    if (minutos != null) payload['minutos'] = minutos;
    if (nota != null) payload['nota'] = nota;
    return await _postRequest('/premium/horas', payload);
  }

  // Configurar sueldo de trabajador
  static Future<Map<String, dynamic>> configurarSueldo({
    required int idAsignacion,
    required int idTrabajoLargo,
    required String emailTrabajador,
    required String emailContratista,
    required String tipoPeriodo,
    required double montoPeriodo,
    String moneda = 'MXN',
    double? horasRequeridasPeriodo,
  }) async {
    final payload = {
      'id_asignacion': idAsignacion,
      'id_trabajo_largo': idTrabajoLargo,
      'email_trabajador': emailTrabajador,
      'email_contratista': emailContratista,
      'tipo_periodo': tipoPeriodo,
      'monto_periodo': montoPeriodo,
      'moneda': moneda,
    };
    if (horasRequeridasPeriodo != null) {
      payload['horas_requeridas_periodo'] = horasRequeridasPeriodo;
    }
    return await _postRequest('/premium/sueldo', payload);
  }

  // Obtener trabajadores de un trabajo
  static Future<Map<String, dynamic>> obtenerTrabajadoresTrabajo({
    required int idTrabajoLargo,
    required String emailContratista,
  }) async {
    return await _getRequest('/premium/trabajadores', {
      'id_trabajo_largo': idTrabajoLargo.toString(),
      'email_contratista': emailContratista,
    });
  }

  // Generar nómina
  static Future<Map<String, dynamic>> generarNomina({
    required int idTrabajoLargo,
    required String emailContratista,
    required String periodoInicio,
    required String periodoFin,
  }) async {
    return await _postRequest('/premium/nomina', {
      'id_trabajo_largo': idTrabajoLargo,
      'email_contratista': emailContratista,
      'periodo_inicio': periodoInicio,
      'periodo_fin': periodoFin,
    });
  }

  // Reiniciar horas de trabajadores después de descargar nómina
  static Future<Map<String, dynamic>> reiniciarHorasTrabajadores({
    required int idTrabajoLargo,
    required String emailContratista,
    required String periodoInicio,
    required String periodoFin,
  }) async {
    return await _postRequest('/premium/reiniciar-horas', {
      'id_trabajo_largo': idTrabajoLargo,
      'email_contratista': emailContratista,
      'periodo_inicio': periodoInicio,
      'periodo_fin': periodoFin,
    });
  }

  // Registrar gasto extra
  static Future<Map<String, dynamic>> registrarGastoExtra({
    required int idTrabajoLargo,
    required String emailContratista,
    required String fechaGasto,
    required double monto,
    required String descripcion,
  }) async {
    return await _postRequest('/premium/gastos-extras', {
      'id_trabajo_largo': idTrabajoLargo,
      'email_contratista': emailContratista,
      'fecha_gasto': fechaGasto,
      'monto': monto.toString(),
      'descripcion': descripcion,
    });
  }

  // Obtener gastos extras
  static Future<Map<String, dynamic>> obtenerGastosExtras({
    required int idTrabajoLargo,
    required String emailContratista,
    String? periodoInicio,
    String? periodoFin,
  }) async {
    final params = <String, String>{
      'id_trabajo_largo': idTrabajoLargo.toString(),
      'email_contratista': emailContratista,
    };
    if (periodoInicio != null) params['periodo_inicio'] = periodoInicio;
    if (periodoFin != null) params['periodo_fin'] = periodoFin;
    
    return await _getRequest('/premium/gastos-extras', params);
  }
}

