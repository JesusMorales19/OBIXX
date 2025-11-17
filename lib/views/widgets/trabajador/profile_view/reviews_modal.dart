import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../services/api_service.dart';
import '../../../../services/format_service.dart';
import '../../../../core/utils/responsive.dart';

class ReviewsModal {
  // Paleta del usuario
  static const Color primaryYellow = Color(0xFFF5B400); // F5B400
  static const Color secondaryOrange = Color(0xFFE67E22); // E67E22
  static const Color whiteColor = Color(0xFFFFFFFF); // FFFFFF
  static const Color lightGray = Color(0xFFEAEAEA); // EAEAEA (usé EAEAEA como gris claro)

  static void show(
    BuildContext context, {
    required String emailTrabajador,
    double? promedioActual,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.obtenerCalificacionesTrabajador(emailTrabajador),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 200,
                  tablet: 220,
                  desktop: 240,
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorContent(
                context,
                snapshot.error?.toString() ?? 'Error desconocido',
              );
            }

            if (snapshot.data?['success'] != true) {
              return _buildErrorContent(
                context,
                snapshot.data?['error']?.toString() ??
                    'No fue posible cargar las reseñas.',
              );
            }

            final List<Map<String, dynamic>> reviews =
                (snapshot.data?['data'] as List<dynamic>? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
                    .toList();

            final double promedio = promedioActual ??
                (reviews.isEmpty
                    ? 0
                    : reviews
                            .map((e) => FormatService.parseDouble(e['estrellas']))
                            .fold<double>(0, (prev, element) => prev + element) /
                        reviews.length);

            return DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 15,
                      tablet: 16,
                      desktop: 18,
                    ),
                    vertical: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 10,
                      tablet: 11,
                      desktop: 12,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 38,
                          tablet: 40,
                          desktop: 42,
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
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reseñas del trabajador',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveFontSize(
                                      context,
                                      mobile: 18,
                                      tablet: 19,
                                      desktop: 20,
                                    ),
                                    fontWeight: FontWeight.bold,
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
                                Row(
                                  children: [
                                    _buildStars(context, promedio, size: 16),
                                    SizedBox(
                                      width: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 6,
                                        tablet: 7,
                                        desktop: 8,
                                      ),
                                    ),
                                    Text(
                                      promedio.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        fontSize: Responsive.getResponsiveFontSize(
                                          context,
                                          mobile: 14,
                                          tablet: 15,
                                          desktop: 16,
                                        ),
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
                                    Text(
                                      '(${reviews.length} reseñas)',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: Responsive.getResponsiveFontSize(
                                          context,
                                          mobile: 11,
                                          tablet: 12,
                                          desktop: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: EdgeInsets.all(
                                Responsive.getResponsiveSpacing(
                                  context,
                                  mobile: 6,
                                  tablet: 7,
                                  desktop: 8,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: lightGray,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: Responsive.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 17,
                                  desktop: 18,
                                ),
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 10,
                          tablet: 11,
                          desktop: 12,
                        ),
                      ),
                      Expanded(
                        child: reviews.isEmpty
                            ? Center(
                                child: Text(
                                  'Aún no hay reseñas para este trabajador.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: Responsive.getResponsiveFontSize(
                                      context,
                                      mobile: 12,
                                      tablet: 13,
                                      desktop: 14,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: reviews.length,
                                padding: EdgeInsets.only(
                                  bottom: Responsive.getResponsiveSpacing(
                                    context,
                                    mobile: 15,
                                    tablet: 18,
                                    desktop: 20,
                                  ),
                                  top: Responsive.getResponsiveSpacing(
                                    context,
                                    mobile: 5,
                                    tablet: 5.5,
                                    desktop: 6,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final r = reviews[index];
                                  final nombre = [
                                    (r['nombre_contratista'] ?? '').toString().trim(),
                                    (r['apellido_contratista'] ?? '').toString().trim(),
                                  ]
                                      .where((element) => element.isNotEmpty)
                                      .join(' ');
                                  final calificacion = FormatService.parseDouble(r['estrellas']);
                                  final resena = (r['resena'] ?? '')
                                      .toString()
                                      .trim();
                                  final foto = r['foto_contratista'] as String?;

                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 6,
                                        tablet: 7,
                                        desktop: 8,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(
                                      Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 12,
                                        tablet: 13,
                                        desktop: 14,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: lightGray.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: Responsive.getResponsiveFontSize(
                                            context,
                                            mobile: 22,
                                            tablet: 24,
                                            desktop: 26,
                                          ),
                                          backgroundImage: _buildAvatar(foto),
                                          backgroundColor: primaryYellow,
                                          child: foto == null
                                              ? Text(
                                                  _initials(nombre),
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
                                                )
                                              : null,
                                        ),
                                        SizedBox(
                                          width: Responsive.getResponsiveSpacing(
                                            context,
                                            mobile: 10,
                                            tablet: 11,
                                            desktop: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      nombre.isEmpty
                                                          ? r['email_contratista']
                                                                  ?.toString() ??
                                                              'Contratista'
                                                          : nombre,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: Responsive.getResponsiveFontSize(
                                                          context,
                                                          mobile: 13,
                                                          tablet: 14,
                                                          desktop: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  _buildStars(context, calificacion,
                                                      size: 16),
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
                                              Text(
                                                resena.isEmpty
                                                    ? 'Sin reseña.'
                                                    : resena,
                                                style: TextStyle(
                                                  fontSize: Responsive.getResponsiveFontSize(
                                                    context,
                                                    mobile: 12,
                                                    tablet: 13,
                                                    desktop: 14,
                                                  ),
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helpers

  static Widget _buildErrorContent(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 18,
          tablet: 21,
          desktop: 24,
        ),
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
          ),
          Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: Responsive.getResponsiveFontSize(
              context,
              mobile: 38,
              tablet: 40,
              desktop: 42,
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Cerrar',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static ImageProvider? _buildAvatar(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final cleaned = base64Image.contains(',')
          ? base64Image.split(',').last
          : base64Image;
      final bytes = base64Decode(cleaned);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }
  }

  // Construye estrellas (rellenas según el valor)
  static Widget _buildStars(BuildContext context, double rating, {double size = 18}) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    final List<Widget> stars = [];
    final starSize = Responsive.getResponsiveFontSize(
      context,
      mobile: 14,
      tablet: 15,
      desktop: size,
    );

    for (var i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, size: starSize, color: primaryYellow));
      } else if (i == fullStars && hasHalf) {
        stars.add(Icon(Icons.star_half, size: starSize, color: primaryYellow));
      } else {
        stars.add(Icon(Icons.star_border, size: starSize, color: primaryYellow.withOpacity(0.7)));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
