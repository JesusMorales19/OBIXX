import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_notification_model.dart';
import '../models/asignacion_trabajo_model.dart';
import 'api_service.dart';
import 'navigation_service.dart';
import 'storage_service.dart';
import '../views/widgets/notifications_overlay.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<AppNotificationModel>> notifications =
      ValueNotifier<List<AppNotificationModel>>(<AppNotificationModel>[]);

  String? _email;
  String? _tipoUsuario;
  bool _isFetching = false;
  bool _tokenRegistered = false;
  bool _initialMessageHandled = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

  String? get currentEmail => _email;
  String? get currentTipoUsuario => _tipoUsuario;

  Future<void> configureForUser({
    required String email,
    required String tipoUsuario,
  }) async {
    final emailChanged = _email != null && _email != email;
    final tipoChanged = _tipoUsuario != null && _tipoUsuario != tipoUsuario;

    _email = email;
    _tipoUsuario = tipoUsuario;

    if (emailChanged || tipoChanged) {
      _tokenRegistered = false;
    }

    await _registerDeviceToken();
    await refreshNotifications();
    await _handleInitialNotification();
  }

  Future<void> refreshNotifications() async {
    if (_isFetching) return;

    if (_email == null || _tipoUsuario == null) {
      final storedUser = await StorageService.getUser();
      _email ??= storedUser?['email'] as String?;
      _tipoUsuario ??= storedUser?['tipoUsuario'] as String?;
    }

    if (_email == null || _tipoUsuario == null) {
      _setNotifications(<AppNotificationModel>[]);
      unreadCount.value = 0;
      return;
    }

    await _registerDeviceToken();

    _isFetching = true;
    try {
      final response = await ApiService.obtenerNotificaciones(
        email: _email!,
        tipoUsuario: _tipoUsuario!,
      );

      if (response['success'] == true) {
        final list = _extractNotifications(response);
        _setNotifications(list);
        unreadCount.value = list.where((n) => !n.leida).length;
        if (_tipoUsuario?.toLowerCase() == 'trabajador') {
          final tieneSolicitud = list.any((n) => n.data['solicitudId'] != null);
          await StorageService.mergeUser({'solicitudPendiente': tieneSolicitud});
        }
      } else {
        _setNotifications(<AppNotificationModel>[]);
        unreadCount.value = 0;
        if (_tipoUsuario?.toLowerCase() == 'trabajador') {
          await StorageService.mergeUser({'solicitudPendiente': false});
        }
      }
    } catch (_) {
      // En caso de error mantenemos los valores actuales pero evitamos bloqueo
    } finally {
      _isFetching = false;
    }
  }

  Future<void> markAsRead(List<int> ids) async {
    if (_email == null || ids.isEmpty) return;

    try {
      await ApiService.marcarNotificacionesLeidas(
        email: _email!,
        ids: ids,
      );

      final updated = notifications.value
          .map((notification) => ids.contains(notification.id)
              ? notification.copyWith(leida: true)
              : notification)
          .toList(growable: false);

      _setNotifications(updated);
      unreadCount.value = updated.where((n) => !n.leida).length;
    } catch (_) {
      // Ignoramos errores de marcado para no interrumpir la UX
    }
  }

  Future<void> clearSession() async {
    _email = null;
    _tipoUsuario = null;
    _setNotifications(<AppNotificationModel>[]);
    unreadCount.value = 0;
    _tokenRegistered = false;
    await _tokenSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedSubscription?.cancel();
    _tokenSubscription = null;
    _onMessageSubscription = null;
    _onMessageOpenedSubscription = null;
  }

  void showNotificationSnack(String message) {
    final context = NavigationService.context;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> deleteAll() async {
    if (_email == null) {
      return;
    }

    try {
      await ApiService.eliminarNotificaciones(email: _email!);
    } catch (_) {
      // Si falla, igual limpiamos localmente para no bloquear la UX
    } finally {
      _setNotifications(<AppNotificationModel>[]);
      unreadCount.value = 0;
      if (_tipoUsuario?.toLowerCase() == 'trabajador') {
        await StorageService.mergeUser({'solicitudPendiente': false});
      }
    }
  }

  void _setNotifications(List<AppNotificationModel> list) {
    notifications.value = List<AppNotificationModel>.unmodifiable(list);
  }

  List<AppNotificationModel> _extractNotifications(Map<String, dynamic> response) {
    final data = response['data'];
    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final nested = data['notificaciones'] ?? data['items'] ?? data['data'];
      rawList = nested is List ? nested : <dynamic>[];
    } else {
      final direct = response['notificaciones'];
      rawList = direct is List ? direct : <dynamic>[];
    }

    return rawList
        .map((item) {
          if (item is Map<String, dynamic>) {
            return AppNotificationModel.fromJson(item);
          }
          return null;
        })
        .whereType<AppNotificationModel>()
        .toList(growable: false);
  }

  void removeNotificationById(int id) {
    final filtered =
        notifications.value.where((notification) => notification.id != id).toList(growable: false);
    _setNotifications(filtered);
    unreadCount.value = filtered.where((n) => !n.leida).length;
  }

  Future<bool> aceptarSolicitud(AppNotificationModel notification) async {
    final solicitudIdRaw = notification.data['solicitudId'];
    final tipoTrabajo = notification.data['tipoTrabajo']?.toString();
    final idTrabajoRaw = notification.data['idTrabajo'];
    final emailTrabajador = notification.data['emailTrabajador']?.toString();

    if (_email == null ||
        solicitudIdRaw == null ||
        tipoTrabajo == null ||
        idTrabajoRaw == null ||
        emailTrabajador == null) {
      showNotificationSnack('No se pudo procesar la solicitud.');
      return false;
    }

    final idSolicitud = int.tryParse(solicitudIdRaw.toString());
    final idTrabajo = int.tryParse(idTrabajoRaw.toString());

    if (idSolicitud == null || idTrabajo == null) {
      showNotificationSnack('Datos incompletos para asignar el trabajo.');
      return false;
    }

    final asignacion = AsignacionTrabajoModel(
      emailContratista: _email!,
      emailTrabajador: emailTrabajador,
      tipoTrabajo: tipoTrabajo,
      idTrabajo: idTrabajo,
      idSolicitud: idSolicitud,
    );

    try {
      final response = await ApiService.asignarTrabajo(asignacion);
      if (response['success'] == true) {
        removeNotificationById(notification.id);
        showNotificationSnack('Trabajador asignado correctamente.');
        await _abrirWhatsAppTrabajador(
          emailTrabajador: emailTrabajador,
          telefonoNotificacion: notification.data['telefonoTrabajador']?.toString(),
        );
        return true;
      } else {
        final errorMsg =
            response['error']?.toString() ?? 'No se pudo asignar el trabajo. Intenta de nuevo.';
        showNotificationSnack(errorMsg);
        return false;
      }
    } catch (error) {
      showNotificationSnack('Error al asignar el trabajo: $error');
      return false;
    }
  }

  Future<String?> calificarTrabajadorDesdeNotificacion({
    required AppNotificationModel notification,
    required int estrellas,
    String? resena,
  }) async {
    if (estrellas < 1 || estrellas > 5) {
      return 'Selecciona una calificación entre 1 y 5 estrellas.';
    }

    String? emailContratista = _email;
    if (emailContratista == null || emailContratista.isEmpty) {
      final storedUser = await StorageService.getUser();
      emailContratista = storedUser?['email']?.toString();
      if (emailContratista != null && emailContratista.isNotEmpty) {
        _email = emailContratista;
      }
    }

    if (emailContratista == null || emailContratista.isEmpty) {
      return 'No se encontró la sesión del contratista.';
    }

    final emailTrabajador = notification.data['emailTrabajador']?.toString();
    if (emailTrabajador == null || emailTrabajador.isEmpty) {
      return 'No se encontró el trabajador asociado a esta notificación.';
    }

    final idAsignacionRaw =
        notification.data['idAsignacion'] ?? notification.data['id_asignacion'];
    final idAsignacion = int.tryParse(idAsignacionRaw?.toString() ?? '');
    if (idAsignacion == null || idAsignacion <= 0) {
      return 'No se pudo identificar la asignación para calificar.';
    }

    final comentario = resena != null && resena.trim().isNotEmpty ? resena.trim() : null;

    try {
      final response = await ApiService.registrarCalificacionTrabajador(
        emailContratista: emailContratista,
        emailTrabajador: emailTrabajador,
        idAsignacion: idAsignacion,
        estrellas: estrellas,
        resena: comentario,
      );

      if (response['success'] == true) {
        try {
          await ApiService.marcarNotificacionesLeidas(
            email: emailContratista,
            ids: [notification.id],
          );
        } catch (_) {
          // Si ocurre un error al marcar como leída, continuamos igualmente
        }

        removeNotificationById(notification.id);
        return null;
      }

      final error = response['error']?.toString();
      return error != null && error.isNotEmpty
          ? error
          : 'No se pudo registrar la calificación. Intenta nuevamente.';
    } catch (error) {
      return 'Error al registrar la calificación: $error';
    }
  }

  Future<void> _abrirWhatsAppTrabajador({
    required String emailTrabajador,
    String? telefonoNotificacion,
  }) async {
    String? telefono = telefonoNotificacion;
    if (telefono == null || telefono.trim().isEmpty) {
      try {
        final perfil = await ApiService.obtenerPerfilTrabajador(emailTrabajador);
        if (perfil['success'] == true) {
          final data = perfil['data'];
          if (data is Map<String, dynamic>) {
            telefono = data['telefono']?.toString();
          }
        }
      } catch (_) {
        // Silenciar errores, se manejarán abajo
      }
    }

    if (telefono == null || telefono.trim().isEmpty) {
      showNotificationSnack('El trabajador no tiene un número de teléfono registrado.');
      return;
    }

    final sanitized = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) {
      showNotificationSnack('El número de teléfono del trabajador no es válido.');
      return;
    }

    final uri = Uri.parse('https://wa.me/$sanitized');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        showNotificationSnack('No se pudo abrir WhatsApp para contactar al trabajador.');
      }
    } catch (_) {
      showNotificationSnack('No se pudo abrir WhatsApp para contactar al trabajador.');
    }
  }

  Future<void> _registerDeviceToken() async {
    if (_tokenRegistered || _email == null || _tipoUsuario == null) return;

    try {
      final messaging = FirebaseMessaging.instance;

      if (!kIsWeb) {
        await messaging.requestPermission();
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final plataforma = kIsWeb
            ? 'web'
            : Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'flutter';
        await ApiService.registrarTokenDispositivo(
          email: _email!,
          tipoUsuario: _tipoUsuario!,
          token: token,
          plataforma: plataforma,
        );
        _tokenRegistered = true;
      }

      _tokenSubscription ??= messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty || _email == null || _tipoUsuario == null) return;
        final plataforma = kIsWeb
            ? 'web'
            : Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'flutter';
        await ApiService.registrarTokenDispositivo(
          email: _email!,
          tipoUsuario: _tipoUsuario!,
          token: newToken,
          plataforma: plataforma,
        );
      });

      _onMessageSubscription ??=
          FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await refreshNotifications();
      });

      _onMessageOpenedSubscription ??=
          FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
    } catch (_) {
      // Si ocurre un error al registrar el token, lo ignoramos para no romper el flujo
    }
  }

  Future<void> _handleInitialNotification() async {
    if (_initialMessageHandled) return;
    _initialMessageHandled = true;

    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        await _onNotificationOpened(message);
      }
    } catch (_) {
      // Ignoramos errores de inicialización
    }
  }

  Future<void> _onNotificationOpened(RemoteMessage message) async {
    if (_tipoUsuario == null) {
      final storedUser = await StorageService.getUser();
      _tipoUsuario ??= storedUser?['tipoUsuario']?.toString();
    }

    if (_tipoUsuario == null) {
      return;
    }

    await refreshNotifications();

    final context = NavigationService.context;
    if (context == null || !context.mounted) {
      return;
    }

    await showNotificationsOverlay(context: context, tipoUsuario: _tipoUsuario!);
  }
}
