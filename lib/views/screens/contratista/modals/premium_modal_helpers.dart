import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../../services/format_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../widgets/custom_notification.dart';

/// Funciones auxiliares compartidas para los modales premium
class PremiumModalHelpers {
  // Instancia de notificaciones locales
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  // Inicializar notificaciones locales
  static Future<void> initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      // Solicitar permisos (Android 13+)
      if (Platform.isAndroid) {
        try {
          final androidInfo = await _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
          if (androidInfo != null) {
            await androidInfo.requestNotificationsPermission().catchError((e) {
              print('⚠️ No se pudo solicitar permiso (no crítico): $e');
            });
          }
        } catch (e) {
          print('⚠️ Error al solicitar permisos (no crítico): $e');
        }
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Cuando el usuario toca la notificación
          if (response.payload != null) {
            try {
              final filePath = response.payload!;
              final file = File(filePath);
              
              if (await file.exists()) {
                // Intentar abrir usando MethodChannel
                try {
                  const platform = MethodChannel('com.obix.app/media_store');
                  await platform.invokeMethod('openFile', {
                    'filePath': filePath,
                    'mimeType': 'application/pdf',
                  });
                  print('✅ Archivo abierto desde notificación');
                } catch (e) {
                  print('⚠️ Error con MethodChannel, intentando con share_plus: $e');
                  // Fallback: usar share_plus para abrir
                  await Share.shareXFiles(
                    [XFile(filePath, mimeType: 'application/pdf')],
                    text: 'Abrir nómina',
                  );
                }
              } else {
                print('⚠️ El archivo no existe: $filePath');
              }
            } catch (e) {
              print('❌ Error al abrir PDF desde notificación: $e');
            }
          }
        },
      );

      _notificationsInitialized = true;
    } catch (e) {
      print('❌ Error al inicializar notificaciones: $e');
    }
  }

  // Mostrar notificación de descarga (como descarga del sistema)
  static Future<void> mostrarNotificacionDescarga(String filePath, String fileName) async {
    try {
      await initializeNotifications();

      // Crear canal de notificación para Android
      if (Platform.isAndroid) {
        try {
          final androidInfo = await _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
          if (androidInfo != null) {
            await androidInfo.createNotificationChannel(
              const AndroidNotificationChannel(
                'descargas_pdf',
                'Descargas',
                description: 'Notificaciones de descarga de archivos',
                importance: Importance.defaultImportance,
                playSound: true,
                enableVibration: true,
              ),
            ).catchError((e) {
              print('⚠️ Error al crear canal: $e');
            });
          }
        } catch (e) {
          print('⚠️ Error al configurar canal: $e');
        }
      }

      final androidDetails = AndroidNotificationDetails(
        'descargas_pdf',
        'Descargas',
        channelDescription: 'Notificaciones de descarga de archivos',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.status,
        autoCancel: true,
        ongoing: false,
        styleInformation: const BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      // Mostrar notificación como descarga completada
      await _notifications.show(
        notificationId,
        'Descarga completada',
        fileName,
        details,
        payload: filePath,
      );

      print('✅ Notificación de descarga mostrada');
    } catch (e) {
      print('❌ Error al mostrar notificación: $e');
    }
  }

  // Función para descargar el PDF usando DownloadManager del sistema
  static Future<void> descargarPDF(
    BuildContext context,
    String pdfBase64,
    Map<String, dynamic> nomina,
  ) async {
    try {
      // Validar que el base64 no esté vacío
      if (pdfBase64.isEmpty) {
        throw Exception('El PDF está vacío');
      }

      // Decodificar base64
      final pdfBytes = base64Decode(pdfBase64);
      if (pdfBytes.isEmpty) {
        throw Exception('El PDF decodificado está vacío');
      }

      // Obtener directorio accesible por FileProvider
      String? filePath;
      String fileName;
      final fecha = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final idTrabajo = nomina['id_trabajo_largo']?.toString() ?? 'trabajo';
      fileName = 'nomina_${idTrabajo}_$fecha.pdf';

      if (Platform.isAndroid) {
        // Usar external files directory que es accesible por FileProvider
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadsDir = Directory('${externalDir.path}/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          filePath = '${downloadsDir.path}/$fileName';
        } else {
          // Fallback: usar cache directory
          final cacheDir = await getTemporaryDirectory();
          filePath = '${cacheDir.path}/$fileName';
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      } else {
        final dir = await getDownloadsDirectory();
        filePath = dir != null ? '${dir.path}/$fileName' : null;
      }

      if (filePath == null) {
        throw Exception('No se pudo acceder al directorio de archivos');
      }

      // Guardar archivo
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Verificar que el archivo se guardó correctamente
      if (!await file.exists()) {
        throw Exception('El archivo no se guardó correctamente');
      }

      // Intentar registrar en DownloadManager para que aparezca en descargas
      try {
        if (Platform.isAndroid) {
          const platform = MethodChannel('com.obix.app/media_store');
          await platform.invokeMethod('scanFile', {
            'filePath': filePath,
            'mimeType': 'application/pdf',
          });
        }
      } catch (e) {
        print('⚠️ No se pudo registrar en DownloadManager (no crítico): $e');
      }

      // Mostrar notificación del sistema como descarga completada
      await mostrarNotificacionDescarga(filePath, fileName);

      // Reiniciar horas de los trabajadores y gastos extras para este período
      String mensajeHoras = '';
      try {
        final idTrabajoLargo = nomina['id_trabajo_largo'] as int?;
        final emailContratista = nomina['email_contratista'] as String?;
        final periodoInicioRaw = nomina['periodo_inicio'];
        final periodoFinRaw = nomina['periodo_fin'];
        
        print('🔍 Datos de la nómina para reinicio:');
        print('   - id_trabajo_largo: $idTrabajoLargo');
        print('   - email_contratista: $emailContratista');
        print('   - periodo_inicio (raw): $periodoInicioRaw');
        print('   - periodo_fin (raw): $periodoFinRaw');

        // Convertir fechas a formato ISO si vienen como DateTime o Timestamp
        String? periodoInicio;
        String? periodoFin;
        
        if (periodoInicioRaw != null) {
          if (periodoInicioRaw is String) {
            periodoInicio = periodoInicioRaw.split('T')[0]; // Tomar solo la parte de la fecha
          } else if (periodoInicioRaw is DateTime) {
            periodoInicio = DateFormat('yyyy-MM-dd').format(periodoInicioRaw);
          } else {
            periodoInicio = periodoInicioRaw.toString().split('T')[0];
          }
        }
        
        if (periodoFinRaw != null) {
          if (periodoFinRaw is String) {
            periodoFin = periodoFinRaw.split('T')[0]; // Tomar solo la parte de la fecha
          } else if (periodoFinRaw is DateTime) {
            periodoFin = DateFormat('yyyy-MM-dd').format(periodoFinRaw);
          } else {
            periodoFin = periodoFinRaw.toString().split('T')[0];
          }
        }

        print('   - periodo_inicio (formateado): $periodoInicio');
        print('   - periodo_fin (formateado): $periodoFin');

        if (idTrabajoLargo != null && emailContratista != null && periodoInicio != null && periodoFin != null) {
          print('📤 Llamando a reiniciarHorasTrabajadores...');
          final reinicioResult = await ApiWrapper.safeCall<Map<String, dynamic>>(
            call: () => ApiService.reiniciarHorasTrabajadores(
              idTrabajoLargo: idTrabajoLargo!,
              emailContratista: emailContratista!,
              periodoInicio: periodoInicio!,
              periodoFin: periodoFin!,
            ),
            errorMessage: 'Error al reiniciar horas',
            showError: false,
          );
          
          if (reinicioResult != null) {
            print('📥 Respuesta recibida: $reinicioResult');
            
            // Verificar que la respuesta sea exitosa
            final data = reinicioResult['data'] as Map<String, dynamic>? ?? reinicioResult;
            if (reinicioResult['success'] == true || data['success'] == true) {
              final presupuestoAnterior = FormatService.parseDouble(data['presupuesto_anterior']);
              final presupuestoActualizado = FormatService.parseDouble(data['presupuesto_actualizado']);
              final totalGastado = FormatService.parseDouble(data['total_gastado']);
              final gastosEliminados = FormatService.parseInt(data['gastos_eliminados']);

              print('✅ Reinicio completado:');
              print('   - Horas reiniciadas para el período');
              if (gastosEliminados > 0) {
                print('   - Gastos extras eliminados: $gastosEliminados');
              }
              if (presupuestoAnterior > 0 && presupuestoActualizado > 0 && totalGastado > 0) {
                print('   - Presupuesto actualizado: \$${FormatService.formatNumber(presupuestoAnterior)} -> \$${FormatService.formatNumber(presupuestoActualizado)}');
                print('   - Total gastado: \$${FormatService.formatNumber(totalGastado)}');

                mensajeHoras = '\n\n✅ Reinicio completado:';
                mensajeHoras += '\n- Horas reiniciadas';
                mensajeHoras += '\n- Gastos extras eliminados';
                mensajeHoras += '\n- Presupuesto: \$${FormatService.formatNumber(presupuestoAnterior)} -> \$${FormatService.formatNumber(presupuestoActualizado)}';
                mensajeHoras += '\n- Total gastado: \$${FormatService.formatNumber(totalGastado)}';
              } else {
                mensajeHoras = '\n\n✅ Las horas y gastos extras han sido reiniciados.';
              }
            } else {
              final errorMsg = data['error']?.toString() ?? reinicioResult['error']?.toString() ?? 'Error desconocido';
              mensajeHoras = '\n\n⚠️ No se pudieron reiniciar las horas y gastos extras: $errorMsg';
              print('⚠️ No se pudieron reiniciar las horas: $errorMsg');
            }
          } else {
            mensajeHoras = '\n\n⚠️ No se pudieron reiniciar las horas y gastos extras';
          }
        } else {
          print('⚠️ Datos incompletos para reiniciar horas');
          mensajeHoras = '\n\n⚠️ No se pudieron reiniciar las horas: datos incompletos';
        }
      } catch (e) {
        print('⚠️ Error al reiniciar horas y gastos extras: $e');
        mensajeHoras = '\n\n⚠️ Error al reiniciar horas y gastos extras: $e';
      }

      if (context.mounted) {
        CustomNotification.showSuccess(
          context,
          'Nómina descargada exitosamente$mensajeHoras',
        );
      }
    } catch (e) {
      print('Error al descargar PDF: $e');
      rethrow;
    }
  }

  // Mostrar resumen de nómina
  static void mostrarResumenNomina(
    BuildContext context,
    Map<String, dynamic> nomina,
    List<dynamic> detalle,
    List<dynamic> gastosExtras,
    num? totalGastosExtras,
    String? pdfBase64,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nómina Generada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presupuesto Total: \$${FormatService.formatNumber(nomina['presupuesto_total'])}'),
                const SizedBox(height: 8),
                Text('Total Pagado a Trabajadores: \$${FormatService.formatNumber(nomina['total_pagado_trabajadores'])}'),
                if (totalGastosExtras != null && totalGastosExtras > 0) ...[
                  const SizedBox(height: 8),
                  Text('Total Gastos Extras: \$${FormatService.formatNumber(totalGastosExtras)}'),
                ],
                const SizedBox(height: 8),
                Text('Saldo Restante: \$${FormatService.formatNumber(nomina['saldo_restante'])}'),
                const Divider(),
                const Text(
                  'Detalle de Trabajadores:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (detalle.isEmpty)
                  const Text('No hay trabajadores con configuración de pago')
                else
                  ...detalle.map((t) {
                    if (t is! Map<String, dynamic>) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${t['nombre'] ?? 'Sin nombre'}: ${FormatService.formatHoras(FormatService.parseDouble(t['horas_trabajadas']))} horas - \$${FormatService.formatNumber(t['monto_pagado'])}',
                      ),
                    );
                  }).toList(),
                if (gastosExtras.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Gastos Extras:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...gastosExtras.map((g) {
                    if (g is! Map<String, dynamic>) return const SizedBox.shrink();
                    final fechaRaw = g['fecha'];
                    String fecha = '';
                    if (fechaRaw != null) {
                      try {
                        // Intentar parsear la fecha
                        DateTime fechaDateTime;
                        if (fechaRaw is String) {
                          // Si viene como string, intentar parsear
                          fechaDateTime = DateTime.parse(fechaRaw.split('T')[0]);
                        } else if (fechaRaw is DateTime) {
                          fechaDateTime = fechaRaw;
                        } else {
                          fechaDateTime = DateTime.parse(fechaRaw.toString().split('T')[0]);
                        }
                        // Formatear como DD/MM/AAAA
                        fecha = FormatService.formatDate(fechaDateTime);
                      } catch (e) {
                        // Si falla el parseo, usar el valor original sin la parte de tiempo
                        fecha = fechaRaw.toString().split('T')[0];
                      }
                    }
                    final descripcion = g['descripcion']?.toString() ?? 'Sin descripción';
                    final monto = FormatService.formatNumber(g['monto']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$fecha - $descripcion: \$$monto',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            if (pdfBase64 != null && pdfBase64.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await descargarPDF(context, pdfBase64, nomina);
                  } catch (e) {
                    CustomNotification.showError(
                      context,
                      'Error al descargar el PDF: $e',
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Descargar Nómina'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F4E79),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }
}

