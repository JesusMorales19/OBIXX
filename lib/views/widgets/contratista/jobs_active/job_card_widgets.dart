import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../custom_notification.dart';

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
          _infoRow('Frecuencia de pago:', frecuenciaPago, 'Vacantes disponibles:', vacantesDisponibles),
          _dividerLine(),
          _infoRow('Fecha Inicio:', fechaInicio, 'Fecha Final:', fechaFinal),
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
          _infoRow('Rango de Precio:', rangoPrecio, 'Vacantes disponibles:', vacantesDisponibles),
          _dividerLine(),
          _infoRow('Especialidad Requerida:', especialidad,
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
    margin: const EdgeInsets.only(bottom: 25),
    padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
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
          padding: const EdgeInsets.only(top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 70),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4E79),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              content,
              const SizedBox(height: 25),

              // Botones más cortos y delgados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 150,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onVerTrabajadores,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AE0C),
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 8),
                      ),
                      child: const Text(
                        'Ver Trabajadores',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onTerminar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 8),
                      ),
                      child: const Text(
                        'Terminar',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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
Widget _infoRow(String label1, String value1, String label2, String value2) {
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
      const SizedBox(width: 10),
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