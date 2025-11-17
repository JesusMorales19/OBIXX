import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../custom_notification.dart';
import '../../../widgets/trabajador/jobs_employee/end_contract_dialog.dart';
import '../../../../core/utils/responsive.dart';

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

  List<Widget> _buildStars(BuildContext context) {
    final rating = calificacionTrabajador ?? 0;
    final estrellasLlenas = rating.floor();
    final tieneMedia = (rating - estrellasLlenas) >= 0.5;
    final starSize = Responsive.getResponsiveFontSize(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );
    return List.generate(5, (index) {
      if (index < estrellasLlenas) {
        return Icon(Icons.star, size: starSize, color: Colors.amber);
      } else if (index == estrellasLlenas && tieneMedia) {
        return Icon(Icons.star_half, size: starSize, color: Colors.amber);
      }
      return Icon(Icons.star_border, size: starSize, color: Colors.amber);
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

  List<Widget> _buildDetalleTrabajo(BuildContext context) {
    final List<Widget> items = [];

    items.add(_infoRow(context, 'Nombre del trabajo:', tituloTrabajo));
    items.add(Divider(
      color: Colors.black26,
      height: Responsive.getResponsiveSpacing(
        context,
        mobile: 1.5,
        tablet: 1.75,
        desktop: 2,
      ),
    ));

    items.add(_infoRow(context, 'Contratista:', nombreContratista));
    items.add(Divider(
      color: Colors.black26,
      height: Responsive.getResponsiveSpacing(
        context,
        mobile: 1.5,
        tablet: 1.75,
        desktop: 2,
      ),
    ));

    if (esTrabajoLargo) {
      if (frecuenciaPago != null && frecuenciaPago!.isNotEmpty) {
        items.add(_infoRow(context, 'Frecuencia de pago:', frecuenciaPago!));
        items.add(Divider(
          color: Colors.black26,
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 1.5,
            tablet: 1.75,
            desktop: 2,
          ),
        ));
      }
      if (tipoObra != null && tipoObra!.isNotEmpty) {
        items.add(_infoRow(context, 'Tipo de obra:', tipoObra!));
        items.add(Divider(
          color: Colors.black26,
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 1.5,
            tablet: 1.75,
            desktop: 2,
          ),
        ));
      }
      if (fechaFinal != null && fechaFinal!.isNotEmpty) {
        items.add(_infoRow(context, 'Fecha final:', fechaFinal!));
        items.add(Divider(
          color: Colors.black26,
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 1.5,
            tablet: 1.75,
            desktop: 2,
          ),
        ));
      }
    } else {
      if (rangoPrecio != null && rangoPrecio!.isNotEmpty) {
        items.add(_infoRow(context, 'Rango de precio:', rangoPrecio!));
        items.add(Divider(
          color: Colors.black26,
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 1.5,
            tablet: 1.75,
            desktop: 2,
          ),
        ));
      }
      if (especialidad != null && especialidad!.isNotEmpty) {
        items.add(_infoRow(context, 'Especialidad:', especialidad!));
        items.add(Divider(
          color: Colors.black26,
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 1.5,
            tablet: 1.75,
            desktop: 2,
          ),
        ));
      }
      if (disponibilidad != null && disponibilidad!.isNotEmpty) {
        items.add(_infoRow(context, 'Disponibilidad:', disponibilidad!));
        items.add(Divider(
          color: Colors.black26,
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 1.5,
            tablet: 1.75,
            desktop: 2,
          ),
        ));
      }
    }

    if (direccion != null && direccion!.isNotEmpty) {
      items.add(_infoRow(context, 'Dirección:', direccion!));
      items.add(Divider(
        color: Colors.black26,
        height: Responsive.getResponsiveSpacing(
          context,
          mobile: 1.5,
          tablet: 1.75,
          desktop: 2,
        ),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 14,
          desktop: 16,
        ),
        vertical: Responsive.getResponsiveSpacing(
          context,
          mobile: 8,
          tablet: 9,
          desktop: 10,
        ),
      ),
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 15,
          tablet: 16,
          desktop: 18,
        ),
      ),
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
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
              color: Colors.green,
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
          Text(
            tituloTrabajo,
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 17,
                tablet: 18,
                desktop: 19,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F4E79),
            ),
          ),
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildDetalleTrabajo(context),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 10,
                        tablet: 11,
                        desktop: 12,
                      ),
                    ),
                    // Mostrar ubicación: botón de Maps si hay coordenadas, dirección si no hay coordenadas pero hay dirección
                    if (latitud != null && longitud != null)
                      ElevatedButton.icon(
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
                          'Ver ubicación',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                          ),
                        ),
                      )
                    else if (direccion != null && direccion!.isNotEmpty)
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
                              direccion!,
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
                ),
              ),

              SizedBox(
                width: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 15,
                  tablet: 17,
                  desktop: 20,
                ),
              ),

              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Transform.translate(
                      offset: Offset(
                        0,
                        -Responsive.getResponsiveSpacing(
                          context,
                          mobile: 10,
                          tablet: 11,
                          desktop: 12,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 3,
                              tablet: 3.5,
                              desktop: 4,
                            ),
                          ),
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
                          radius: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 45,
                            tablet: 47,
                            desktop: 50,
                          ),
                          backgroundImage: _obtenerImagen(),
                        ),
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
                    Text(
                      nombreTrabajador,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 3,
                        tablet: 3.5,
                        desktop: 4,
                      ),
                    ),
                    Text(
                      _calificacionTexto(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 11,
                          tablet: 11.5,
                          desktop: 12,
                        ),
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 2,
                        tablet: 2.5,
                        desktop: 3,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildStars(context),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 15,
              tablet: 16,
              desktop: 18,
            ),
          ),

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
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 25,
                    tablet: 27,
                    desktop: 30,
                  ),
                  vertical: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 11,
                    desktop: 12,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Cancelar contrato",
                style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  // Helper fila texto
  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.getResponsiveSpacing(
          context,
          mobile: 2,
          tablet: 2.5,
          desktop: 3,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: Responsive.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: "$label ",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: const Color(0xFF555555),
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
