import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../custom_notification.dart';
import '../../../widgets/trabajador/jobs_employee/end_contract_dialog.dart';

class WorkerCardJobs extends StatelessWidget {
  final bool esTrabajoLargo;
  final String tituloTrabajo;
  final String nombreContratista;
  final String? rangoPrecio;
  final String? especialidad;
  final String? disponibilidad;
  final String? frecuenciaPago;
  final String? tipoObra;
  final String? fechaFinal;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final String nombreTrabajador;
  final String? fotoTrabajadorBase64;
  final double? calificacionTrabajador;
  final VoidCallback? onCancelarContrato;

  const WorkerCardJobs({
    super.key,
    required this.esTrabajoLargo,
    required this.tituloTrabajo,
    required this.nombreContratista,
    required this.nombreTrabajador,
    this.rangoPrecio,
    this.especialidad,
    this.disponibilidad,
    this.frecuenciaPago,
    this.tipoObra,
    this.fechaFinal,
    this.direccion,
    this.latitud,
    this.longitud,
    this.fotoTrabajadorBase64,
    this.calificacionTrabajador,
    this.onCancelarContrato,
  });

  ImageProvider _obtenerImagen() {
    if (fotoTrabajadorBase64 != null && fotoTrabajadorBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(fotoTrabajadorBase64!);
        return MemoryImage(bytes);
      } catch (_) {
        // ignorar y usar imagen por defecto
      }
    }
    return const AssetImage('assets/images/albañil.png');
  }

  String _calificacionTexto() {
    final rating = calificacionTrabajador;
    if (rating == null) return 'Sin calificación';
    return '${rating.toStringAsFixed(1)}/5.0';
  }

  List<Widget> _buildStars() {
    final rating = calificacionTrabajador ?? 0;
    final estrellasLlenas = rating.floor();
    final tieneMedia = (rating - estrellasLlenas) >= 0.5;
    return List.generate(5, (index) {
      if (index < estrellasLlenas) {
        return const Icon(Icons.star, size: 16, color: Colors.amber);
      } else if (index == estrellasLlenas && tieneMedia) {
        return const Icon(Icons.star_half, size: 16, color: Colors.amber);
      }
      return const Icon(Icons.star_border, size: 16, color: Colors.amber);
    });
  }

  Future<void> _abrirMapa(BuildContext context) async {
    if (latitud == null || longitud == null) {
      CustomNotification.showError(
        context,
        'No hay coordenadas disponibles para este trabajo.',
      );
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitud,$longitud');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      CustomNotification.showError(
        context,
        'No se pudo abrir la ubicación en Maps.',
      );
    }
  }

  List<Widget> _buildDetalleTrabajo() {
    final List<Widget> items = [];

    items.add(_infoRow('Nombre del trabajo:', tituloTrabajo));
    items.add(const Divider(color: Colors.black26, height: 2));

    items.add(_infoRow('Contratista:', nombreContratista));
    items.add(const Divider(color: Colors.black26, height: 2));

    if (esTrabajoLargo) {
      if (frecuenciaPago != null && frecuenciaPago!.isNotEmpty) {
        items.add(_infoRow('Frecuencia de pago:', frecuenciaPago!));
        items.add(const Divider(color: Colors.black26, height: 2));
      }
      if (tipoObra != null && tipoObra!.isNotEmpty) {
        items.add(_infoRow('Tipo de obra:', tipoObra!));
        items.add(const Divider(color: Colors.black26, height: 2));
      }
      if (fechaFinal != null && fechaFinal!.isNotEmpty) {
        items.add(_infoRow('Fecha final:', fechaFinal!));
        items.add(const Divider(color: Colors.black26, height: 2));
      }
    } else {
      if (rangoPrecio != null && rangoPrecio!.isNotEmpty) {
        items.add(_infoRow('Rango de precio:', rangoPrecio!));
        items.add(const Divider(color: Colors.black26, height: 2));
      }
      if (especialidad != null && especialidad!.isNotEmpty) {
        items.add(_infoRow('Especialidad:', especialidad!));
        items.add(const Divider(color: Colors.black26, height: 2));
      }
      if (disponibilidad != null && disponibilidad!.isNotEmpty) {
        items.add(_infoRow('Disponibilidad:', disponibilidad!));
        items.add(const Divider(color: Colors.black26, height: 2));
      }
    }

    if (direccion != null && direccion!.isNotEmpty) {
      items.add(_infoRow('Dirección:', direccion!));
      items.add(const Divider(color: Colors.black26, height: 2));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esTrabajoLargo ? 'Trabajo de largo plazo' : 'Trabajo de corto plazo',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tituloTrabajo,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4E79),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildDetalleTrabajo(),
                    const SizedBox(height: 12),
                    // Mostrar ubicación: botón de Maps si hay coordenadas, dirección si no hay coordenadas pero hay dirección
                    if (latitud != null && longitud != null)
                      ElevatedButton.icon(
                        onPressed: () => _abrirMapa(context),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver ubicación'),
                      )
                    else if (direccion != null && direccion!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF1F4E79), size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              direccion!,
                              style: const TextStyle(
                                color: Color(0xFF1F4E79),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _obtenerImagen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nombreTrabajador,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calificacionTexto(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildStars(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Botón Cancelar Contrato
          Center(
            child: ElevatedButton(
              onPressed: () {
                EndContractDialog.show(context, () {
                  onCancelarContrato?.call();
                });
              },
              style: ElevatedButton.styleFrom(
                elevation: 6,
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Cancelar contrato",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper fila texto
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
