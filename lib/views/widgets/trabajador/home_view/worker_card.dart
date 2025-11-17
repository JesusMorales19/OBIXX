import 'package:flutter/material.dart';
import 'modal_detail_short.dart';
import 'modal_detail_length.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../custom_notification.dart';
import '../../../../core/utils/responsive.dart';

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
      margin: EdgeInsets.only(
        bottom: Responsive.getResponsiveSpacing(
          context,
          mobile: 15,
          tablet: 18,
          desktop: 20,
        ),
      ),
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 15,
        ),
      ),
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
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 5,
                    tablet: 5.5,
                    desktop: 6,
                  ),
                  vertical: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 3,
                    tablet: 3.5,
                    desktop: 4,
                  ),
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 9,
                      tablet: 9.5,
                      desktop: 10,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 5,
              tablet: 5.5,
              desktop: 6,
            ),
          ),
          if (payout.isNotEmpty) ...[
            Text(
              '${payoutLabel ?? 'Frecuencia de trabajo'}: $payout${moneda != null ? ' $moneda' : ''}',
              style: TextStyle(
                color: const Color(0xFF1F4E79),
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 5,
                tablet: 5.5,
                desktop: 6,
              ),
            ),
          ],
          // Mostrar ubicación: botón de Maps si hay coordenadas, dirección si no hay coordenadas pero hay dirección
          if (latitud != null && longitud != null) ...[
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 5,
                tablet: 5.5,
                desktop: 6,
              ),
            ),
            TextButton.icon(
              onPressed: () => _abrirMapa(context),
              icon: Icon(
                Icons.map_outlined,
                size: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 19,
                  desktop: 20,
                ),
              ),
              label: Text(
                'Ver ubicación en Maps',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 14,
                  ),
                ),
              ),
            ),
          ] else if (ubication.isNotEmpty && ubication != 'Sin dirección') ...[
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 5,
                tablet: 5.5,
                desktop: 6,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(0xFF1F4E79),
                  size: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 17,
                    desktop: 18,
                  ),
                ),
                SizedBox(
                  width: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 5,
                    tablet: 5.5,
                    desktop: 6,
                  ),
                ),
                Expanded(
                  child: Text(
                    ubication,
                    style: TextStyle(
                      color: const Color(0xFF1F4E79),
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (vacancies != null) ...[
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 5,
                tablet: 5.5,
                desktop: 6,
              ),
            ),
            Text(
              'Vacantes disponibles: $vacancies',
              style: TextStyle(
                color: Colors.black87,
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 11,
                  tablet: 12,
                  desktop: 13,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 15,
            ),
          ),
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
                  minimumSize: Size(
                    Responsive.isMobile(context) ? 110.0 : 120.0,
                    Responsive.getResponsiveSpacing(
                      context,
                      mobile: 36,
                      tablet: 38,
                      desktop: 40,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Ver detalles',
                  style: TextStyle(
                    color: const Color(0xFF5A5A5A),
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 11,
                      tablet: 11.5,
                      desktop: 12,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showApplyButton)
                ElevatedButton(
                  onPressed: (canApply && !isApplying) ? onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F4E79),
                    minimumSize: Size(
                      Responsive.isMobile(context) ? 110.0 : 120.0,
                      Responsive.getResponsiveSpacing(
                        context,
                        mobile: 36,
                        tablet: 38,
                        desktop: 40,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: const Color(0xFF5A6F90),
                  ),
                  child: isApplying
                      ? SizedBox(
                          height: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 17,
                            desktop: 18,
                          ),
                          width: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 17,
                            desktop: 18,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Aplicar Ahora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 11,
                              tablet: 11.5,
                              desktop: 12,
                            ),
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
