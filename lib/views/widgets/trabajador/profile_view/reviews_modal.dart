import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../services/api_service.dart';
import '../../../../services/format_service.dart';

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
              return const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 6,
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reseñas del trabajador',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildStars(promedio, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      promedio.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${reviews.length} reseñas)',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: lightGray,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: reviews.isEmpty
                            ? Center(
                                child: Text(
                                  'Aún no hay reseñas para este trabajador.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: reviews.length,
                                padding:
                                    const EdgeInsets.only(bottom: 20, top: 6),
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
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: lightGray.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundImage: _buildAvatar(foto),
                                          backgroundColor: primaryYellow,
                                          child: foto == null
                                              ? Text(
                                                  _initials(nombre),
                                                  style: const TextStyle(
                                                    color: whiteColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
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
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  _buildStars(calificacion,
                                                      size: 16),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                resena.isEmpty
                                                    ? 'Sin reseña.'
                                                    : resena,
                                                style: TextStyle(
                                                  fontSize: 14,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Cerrar'),
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
  static Widget _buildStars(double rating, {double size = 18}) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    final List<Widget> stars = [];

    for (var i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, size: size, color: primaryYellow));
      } else if (i == fullStars && hasHalf) {
        stars.add(Icon(Icons.star_half, size: size, color: primaryYellow));
      } else {
        stars.add(Icon(Icons.star_border, size: size, color: primaryYellow.withOpacity(0.7)));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
