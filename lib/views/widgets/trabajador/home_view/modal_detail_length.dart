import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

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
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveSpacing(
              context,
              mobile: 50,
              tablet: 55,
              desktop: 60,
            ),
          ),
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
                  padding: EdgeInsets.all(
                    Responsive.getResponsiveSpacing(
                      context,
                      mobile: 15,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 45,
                            tablet: 47,
                            desktop: 50,
                          ),
                          height: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 5,
                            tablet: 5.5,
                            desktop: 6,
                          ),
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),

                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 21,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 9,
                          desktop: 10,
                        ),
                      ),

                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 15,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),

                      if (contratistaNombre != null)
                        _info(context, Icons.person, 'Contratista', contratistaNombre, primaryYellow),
                      _info(context, Icons.people, 'Vacantes', '$vacantes', primaryYellow),
                      _info(context, Icons.schedule, 'Frecuencia de trabajo', frecuenciaPago, secondaryOrange),
                      _info(context, Icons.date_range, 'Fecha de inicio', fechaInicio, primaryYellow),
                      _info(context, Icons.calendar_today, 'Fecha final', fechaFinal, secondaryOrange),
                      _info(context, Icons.apartment, 'Tipo de obra', tipoObra, primaryYellow),

                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 25,
                        ),
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryYellow,
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 50,
                                tablet: 55,
                                desktop: 60,
                              ),
                              vertical: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cerrar',
                            style: TextStyle(
                              color: whiteColor,
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
              },
            ),
          ),
        );
      },
    );
  }

  static Widget _info(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: Responsive.getResponsiveSpacing(
          context,
          mobile: 5,
          tablet: 5.5,
          desktop: 6,
        ),
      ),
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 10,
          tablet: 11,
          desktop: 12,
        ),
      ),
      decoration: BoxDecoration(
        color: lightGray.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: Responsive.getResponsiveFontSize(
              context,
              mobile: 18,
              tablet: 19,
              desktop: 20,
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
            child: Text(
              '$label: $value',
              style: TextStyle(
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
    );
  }
}
