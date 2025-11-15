import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/app_notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/format_service.dart';
import 'contratista/home_view/profile_modal.dart';
import 'custom_notification.dart';

Future<void> showNotificationsOverlay({
  required BuildContext context,
  required String tipoUsuario,
}) async {
  final notificationService = NotificationService.instance;
  await notificationService.refreshNotifications();
  final idsPorLeer = notificationService.notifications.value
      .where((n) => !n.leida)
      .map((n) => n.id)
      .toList();

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.2),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return GestureDetector(
        onVerticalDragUpdate: (details) {
          // Detectar deslizamiento hacia arriba mientras se mueve
          if (details.primaryDelta != null && details.primaryDelta! < -10) {
            // El usuario está deslizando hacia arriba
          }
        },
        onVerticalDragEnd: (details) {
          // Si el usuario desliza hacia arriba (velocidad negativa), cerrar
          if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      // Indicador visual para deslizar hacia arriba
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/images/Casa.png', height: 50),
                          Image.asset('assets/images/obix.png', height: 50),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Image.asset(
                              'assets/images/notificacion.png',
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await notificationService.deleteAll();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Borrar notificaciones'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ValueListenableBuilder<List<AppNotificationModel>>(
                        valueListenable: notificationService.notifications,
                        builder: (context, notificaciones, _) {
                          if (notificaciones.isEmpty) {
                            return const Center(
                              child: Text(
                                'No tienes notificaciones pendientes.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            separatorBuilder: (_, __) => const SizedBox(height: 20),
                            itemCount: notificaciones.length,
                            itemBuilder: (context, index) {
                              final notification = notificaciones[index];
                              return _NotificationCardItem(
                                notification: notification,
                                tipoUsuario: tipoUsuario,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  if (idsPorLeer.isNotEmpty) {
    await notificationService.markAsRead(idsPorLeer);
  }
}

class _NotificationCardItem extends StatefulWidget {
  final AppNotificationModel notification;
  final String tipoUsuario;

  const _NotificationCardItem({
    required this.notification,
    required this.tipoUsuario,
  });

  @override
  State<_NotificationCardItem> createState() => _NotificationCardItemState();
}

class _NotificationCardItemState extends State<_NotificationCardItem> {
  bool _isProcessing = false;
  final TextEditingController _comentarioController = TextEditingController();
  double _rating = 0;
  NotificationService get _service => NotificationService.instance;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  bool get _esSolicitudPendiente =>
      widget.tipoUsuario.toLowerCase() == 'contratista' &&
      widget.notification.data['solicitudId'] != null;

  bool get _esCalificacionPendiente =>
      widget.tipoUsuario.toLowerCase() == 'contratista' &&
      widget.notification.data['idAsignacion'] != null &&
      widget.notification.data['emailTrabajador'] != null;

  String _encabezado() {
    final rolEtiqueta =
        widget.tipoUsuario.toLowerCase() == 'contratista' ? 'Trabajador' : 'Contratista';
    final nombreDesdeData = widget.tipoUsuario.toLowerCase() == 'contratista'
        ? (widget.notification.data['nombreTrabajador'] ??
            widget.notification.data['nombre'] ??
            '')
        : (widget.notification.data['nombreContratista'] ??
            widget.notification.data['nombre'] ??
            '');
    if (nombreDesdeData is String && nombreDesdeData.trim().isNotEmpty) {
      return '$rolEtiqueta: ${nombreDesdeData.trim()}';
    }
    return widget.notification.titulo;
  }

  Future<void> _abrirPerfil() async {
    final email = widget.notification.data['emailTrabajador']?.toString();
    if (email == null || email.isEmpty) {
      _service.showNotificationSnack('No se pudo abrir el perfil del trabajador.');
      return;
    }

    final nombre = widget.notification.data['nombreTrabajador']?.toString() ?? 'Trabajador';
    final categoria =
        widget.notification.data['categoriaTrabajador']?.toString() ?? 'Cargando...';
    final experiencia = FormatService.parseInt(
      widget.notification.data['experienciaTrabajador'],
    );
    final telefono =
        widget.notification.data['telefonoTrabajador']?.toString() ?? '';

    showProfileModal(
      context,
      nombre,
      0,
      categoria,
      'Cargando...',
      '',
      0,
      experiencia,
      'Disponible',
      Colors.green,
      email,
      telefono,
    );
  }

  Future<void> _aceptarSolicitud() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _service.aceptarSolicitud(widget.notification);
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _calificarTrabajador() async {
    if (_isProcessing) return;
    if (_rating < 1) {
      CustomNotification.showError(context, 'Selecciona una calificación.');
      return;
    }

    setState(() => _isProcessing = true);
    final error = await _service.calificarTrabajadorDesdeNotificacion(
      notification: widget.notification,
      estrellas: _rating.toInt(),
      resena: _comentarioController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isProcessing = false);

    if (error == null) {
      CustomNotification.showSuccess(
        context,
        'Calificación registrada correctamente.',
      );
    } else {
      CustomNotification.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextoNotificacion =
        widget.notification.data['contexto']?.toString() ?? '';
    final tituloTrabajo = widget.notification.data['tituloTrabajo']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _encabezado(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.notification.cuerpo,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
          if (_esSolicitudPendiente) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _aceptarSolicitud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Aceptar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _abrirPerfil,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ver Perfil',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_esCalificacionPendiente) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      '${_rating.toInt()}/5.0',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          Icons.star,
                          color: index < _rating ? Colors.amber : Colors.white38,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tituloTrabajo.isNotEmpty
                              ? 'Trabajo: "$tituloTrabajo"'
                              : 'Trabajo desvinculado',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        contextoNotificacion == 'cancelado'
                            ? 'Desvinculación'
                            : 'Trabajo finalizado',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _comentarioController,
                    maxLength: 100,
                    maxLines: 3,
                    decoration: InputDecoration(
                      counterStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      hintText: 'Ayuda al trabajador con una reseña.',
                      hintStyle: const TextStyle(color: Colors.white54),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _calificarTrabajador,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Calificar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
