import 'package:flutter/material.dart';

class ModalTrabajoLargo {
  static const Color primaryYellow = Color(0xFFF5B400);
  static const Color secondaryOrange = Color(0xFFE67E22);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFEAEAEA);

  static void show(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required int vacantes,
    required String frecuenciaPago,
    required String fechaInicio,
    required String fechaFinal,
    required String tipoObra,
    String? contratistaNombre,
    String? direccion,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        // Margen superior visible
        return Padding(
          padding: const EdgeInsets.only(top: 60), // 👈 margen superior visible
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78, // 👈 se queda más abajo
              minChildSize: 0.5,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 6,
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        descripcion,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),

                      const SizedBox(height: 18),

                      if (contratistaNombre != null)
                        _info(Icons.person, 'Contratista', contratistaNombre, primaryYellow),
                      _info(Icons.people, 'Vacantes', '$vacantes', primaryYellow),
                      _info(Icons.schedule, 'Frecuencia de trabajo', frecuenciaPago, secondaryOrange),
                      _info(Icons.date_range, 'Fecha de inicio', fechaInicio, primaryYellow),
                      _info(Icons.calendar_today, 'Fecha final', fechaFinal, secondaryOrange),
                      _info(Icons.apartment, 'Tipo de obra', tipoObra, primaryYellow),

                      const SizedBox(height: 25),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryYellow,
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Widget _info(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGray.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
