import 'package:flutter/material.dart';
import 'modal_detail_short.dart';
import 'modal_detail_length.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../custom_notification.dart';

class WorkerCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final String ubication;
  final String payout;
  final String? moneda;
  final bool isLongTerm;
  final int? vacancies;
  final String? contratista;
  final String? tipoObra;
  final String? fechaInicio;
  final String? fechaFinal;
  final String? descripcion;
  final String? payoutLabel;
  final List<String>? imagenesBase64;
  final String? disponibilidad;
  final String? especialidad;
  final double? latitud;
  final double? longitud;
  final VoidCallback? onApply;
  final bool canApply;
  final bool showApplyButton;
  final bool isApplying;

  const WorkerCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.ubication,
    required this.payout,
    this.moneda,
    required this.isLongTerm,
    this.vacancies,
    this.contratista,
    this.tipoObra,
    this.fechaInicio,
    this.fechaFinal,
    this.descripcion,
    this.payoutLabel,
    this.imagenesBase64,
    this.disponibilidad,
    this.especialidad,
    this.latitud,
    this.longitud,
    this.onApply,
    this.canApply = true,
    this.showApplyButton = true,
    this.isApplying = false,
  });

  Future<void> _abrirMapa(BuildContext context) async {
    if (latitud == null || longitud == null) {
      CustomNotification.showError(
        context,
        'No hay coordenadas disponibles para este trabajo.',
      );
      return;
    }

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitud,$longitud');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      CustomNotification.showError(
        context,
        'No se pudo abrir Maps.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (payout.isNotEmpty) ...[
            Text(
              '${payoutLabel ?? 'Frecuencia de trabajo'}: $payout${moneda != null ? ' $moneda' : ''}',
              style: const TextStyle(
                color: Color(0xFF1F4E79),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          // Mostrar ubicación: botón de Maps si hay coordenadas, dirección si no hay coordenadas pero hay dirección
          if (latitud != null && longitud != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => _abrirMapa(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver ubicación en Maps'),
            ),
          ] else if (ubication.isNotEmpty && ubication != 'Sin dirección') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1F4E79), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ubication,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (vacancies != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Vacantes disponibles: $vacancies',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  if (isLongTerm) {
                    ModalTrabajoLargo.show(
                      context,
                      titulo: title,
                      descripcion: descripcion ?? 'Sin descripción',
                      contratistaNombre: contratista,
                      vacantes: vacancies ?? 0,
                      frecuenciaPago: payout,
                      fechaInicio: fechaInicio ?? 'No especificada',
                      fechaFinal: fechaFinal ?? 'No especificada',
                      tipoObra: tipoObra ?? 'No especificado',
                      direccion: ubication,
                    );
                  } else {
                    ModalTrabajoCorto.show(
                      context,
                      titulo: title,
                      descripcion: descripcion ?? 'Sin descripción',
                      rangoPrecio: payout,
                      fotos: imagenesBase64 ?? const [],
                      disponibilidad: disponibilidad ?? 'No especificada',
                      especialidad: especialidad ?? 'No especificada',
                      contratistaNombre: contratista,
                    );
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEAEAEA),
                  minimumSize: const Size(120, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ver detalles',
                  style: TextStyle(
                    color: Color(0xFF5A5A5A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showApplyButton)
                ElevatedButton(
                  onPressed: (canApply && !isApplying) ? onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F4E79),
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: const Color(0xFF5A6F90),
                  ),
                  child: isApplying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Aplicar Ahora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
