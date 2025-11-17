import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../custom_notification.dart';
import '../../../../core/utils/responsive.dart';

//
// 🔹 CARD LARGO PLAZO
//
class JobCardLargo extends StatelessWidget {
  final String title;
  final String frecuenciaPago;
  final String vacantesDisponibles;
  final int vacantesDisponiblesInt;
  final String tipoObra;
  final String fechaInicio;
  final String fechaFinal;
  final double? latitud;
  final double? longitud;
  final String? direccion;
  final String estado;
  final VoidCallback? onVerTrabajadores;
  final VoidCallback? onTerminar;

  const JobCardLargo({
    super.key,
    required this.title,
    required this.frecuenciaPago,
    required this.vacantesDisponibles,
    required this.vacantesDisponiblesInt,
    required this.tipoObra,
    required this.fechaInicio,
    required this.fechaFinal,
    this.latitud,
    this.longitud,
    this.direccion,
    required this.estado,
    this.onVerTrabajadores,
    this.onTerminar,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = _resolveBadgeText(estado, vacantesDisponiblesInt);
    final badgeColor = _resolveBadgeColor(estado, vacantesDisponiblesInt);

    return _buildBaseCard(
      context: context,
      title: title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, 'Frecuencia de pago:', frecuenciaPago, 'Vacantes disponibles:', vacantesDisponibles),
          _dividerLine(),
          _infoRow(context, 'Fecha Inicio:', fechaInicio, 'Fecha Final:', fechaFinal),
        ],
      ),
      onVerTrabajadores: onVerTrabajadores,
      onTerminar: onTerminar,
      badgeText: badgeText,
      badgeColor: badgeColor,
    );
  }
}

//
// 🔹 CARD CORTO PLAZO
//
class JobCardCorto extends StatelessWidget {
  final String title;
  final String rangoPrecio;
  final String especialidad;
  final String disponibilidad;
  final double? latitud;
  final double? longitud;
  final String vacantesDisponibles;
  final String? fechaCreacion;
  final int vacantesDisponiblesInt;
  final String estado;
  final VoidCallback? onVerTrabajadores;
  final VoidCallback? onTerminar;

  const JobCardCorto({
    super.key,
    required this.title,
    required this.rangoPrecio,
    required this.especialidad,
    required this.disponibilidad,
    this.latitud,
    this.longitud,
    required this.vacantesDisponibles,
    this.fechaCreacion,
    required this.vacantesDisponiblesInt,
    required this.estado,
    this.onVerTrabajadores,
    this.onTerminar,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = _resolveBadgeText(estado, vacantesDisponiblesInt);
    final badgeColor = _resolveBadgeColor(estado, vacantesDisponiblesInt);

    return _buildBaseCard(
      context: context,
      title: title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, 'Rango de Precio:', rangoPrecio, 'Vacantes disponibles:', vacantesDisponibles),
          _dividerLine(),
          _infoRow(context, 'Especialidad Requerida:', especialidad,
              'Trabajo creado:', fechaCreacion ?? 'No especificada'),
        ],
      ),
      onVerTrabajadores: onVerTrabajadores,
      onTerminar: onTerminar,
      badgeText: badgeText,
      badgeColor: badgeColor,
    );
  }
}

//
// 🔹 BASE CARD COMPARTIDA
//
Widget _buildBaseCard({
  required BuildContext context,
  required String title,
  required Widget content,
  required VoidCallback? onVerTrabajadores,
  required VoidCallback? onTerminar,
  required String badgeText,
  required Color badgeColor,
}) {
  return Container(
    margin: EdgeInsets.only(
      bottom: Responsive.getResponsiveSpacing(
        context,
        mobile: 20,
        tablet: 22,
        desktop: 25,
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      Responsive.getResponsiveSpacing(
        context,
        mobile: 12,
        tablet: 13,
        desktop: 15,
      ),
      Responsive.getResponsiveSpacing(
        context,
        mobile: 15,
        tablet: 18,
        desktop: 20,
      ),
      Responsive.getResponsiveSpacing(
        context,
        mobile: 12,
        tablet: 13,
        desktop: 15,
      ),
      Responsive.getResponsiveSpacing(
        context,
        mobile: 15,
        tablet: 18,
        desktop: 20,
      ),
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFDCE6F2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 15,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 60,
                    tablet: 65,
                    desktop: 70,
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 19,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F4E79),
                  ),
                ),
              ),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 6,
                  tablet: 7,
                  desktop: 8,
                ),
              ),
              content,
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 25,
                ),
              ),

              // Botones más cortos y delgados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: Responsive.isMobile(context) ? 140 : 150,
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 28,
                      tablet: 29,
                      desktop: 30,
                    ),
                    child: ElevatedButton(
                      onPressed: onVerTrabajadores,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AE0C),
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 7,
                            desktop: 8,
                          ),
                        ),
                      ),
                      child: Text(
                        'Ver Trabajadores',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.isMobile(context) ? 140 : 150,
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 28,
                      tablet: 29,
                      desktop: 30,
                    ),
                    child: ElevatedButton(
                      onPressed: onTerminar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 7,
                            desktop: 8,
                          ),
                        ),
                      ),
                      child: Text(
                        'Terminar',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Etiqueta "Activo"
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getResponsiveSpacing(
                context,
                mobile: 6,
                tablet: 7,
                desktop: 8,
              ),
              vertical: Responsive.getResponsiveSpacing(
                context,
                mobile: 0.5,
                tablet: 0.75,
                desktop: 1,
              ),
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

//
// 🔹 Divider entre los campos
//
Widget _dividerLine() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    height: 1,
    color: const Color(0xFFDCE6F2),
  );
}

//
// 🔹 Filas de información
//
Widget _infoRow(BuildContext context, String label1, String value1, String label2, String value2) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        flex: 1,
        child: RichText(
          text: TextSpan(
            text: '$label1 ',
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: value1,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(
        width: Responsive.getResponsiveSpacing(
          context,
          mobile: 8,
          tablet: 9,
          desktop: 10,
        ),
      ),
      Expanded(
        flex: 1,
        child: RichText(
          text: TextSpan(
            text: '$label2 ',
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: value2,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

String _resolveBadgeText(String estado, int vacantes) {
  if (estado == 'cancelado') {
    return 'Cancelado';
  }
  if (estado == 'completado') {
    return 'Completado';
  }
  if (estado == 'pausado' || vacantes <= 0) {
    return 'En proceso';
  }
  return 'Activo';
}

Color _resolveBadgeColor(String estado, int vacantes) {
  if (estado == 'cancelado') {
    return const Color(0xFFE53935);
  }
  if (estado == 'completado') {
    return const Color(0xFF546E7A);
  }
  if (estado == 'pausado' || vacantes <= 0) {
    return const Color(0xFFF57C00);
  }
  return const Color(0xFF00AE0C);
}