import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../../core/utils/responsive.dart';

class ModalTrabajoCorto {
  static const Color primaryYellow = Color(0xFFF5B400);
  static const Color secondaryOrange = Color(0xFFE67E22);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFEAEAEA);

  static void show(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required String rangoPrecio,
    required List<String> fotos,
    required String disponibilidad,
    required String especialidad,
    String? contratistaNombre,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        // Agregamos un padding superior para que el modal no suba hasta arriba
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
              initialChildSize: 0.78, // 👈 más bajo por defecto
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
                      if (contratistaNombre != null && contratistaNombre.isNotEmpty)
                        _buildInfo(context, Icons.person, 'Contratista', contratistaNombre, primaryYellow),
                      _buildInfo(context, Icons.attach_money, 'Rango de precio', rangoPrecio, primaryYellow),
                      _buildInfo(context, Icons.access_time, 'Disponibilidad', disponibilidad, primaryYellow),
                      _buildInfo(context, Icons.build, 'Especialidad requerida', especialidad, secondaryOrange),

                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 15,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                      Text(
                        'Fotos del trabajo:',
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
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 8,
                          tablet: 9,
                          desktop: 10,
                        ),
                      ),

                      fotos.isEmpty
                          ? const Text(
                              'No se proporcionaron imágenes para este trabajo.',
                              style: TextStyle(color: Colors.grey),
                            )
                          : SizedBox(
                              height: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 100,
                                tablet: 105,
                                desktop: 110,
                              ),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: fotos.length,
                                separatorBuilder: (_, __) => SizedBox(
                                  width: Responsive.getResponsiveSpacing(
                                    context,
                                    mobile: 10,
                                    tablet: 11,
                                    desktop: 12,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final base64Data = fotos[index];
                                  try {
                                    final bytes = base64Decode(base64Data);
                                    return GestureDetector(
                                      onTap: () => _showImagePreview(context, bytes, titulo),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          bytes,
                                          width: Responsive.getResponsiveSpacing(
                                            context,
                                            mobile: 140,
                                            tablet: 145,
                                            desktop: 150,
                                          ),
                                          height: Responsive.getResponsiveSpacing(
                                            context,
                                            mobile: 90,
                                            tablet: 95,
                                            desktop: 100,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    return Container(
                                      width: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 140,
                                        tablet: 145,
                                        desktop: 150,
                                      ),
                                      height: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 90,
                                        tablet: 95,
                                        desktop: 100,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Imagen inválida',
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveFontSize(
                                            context,
                                            mobile: 11,
                                            tablet: 12,
                                            desktop: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),

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
                            backgroundColor: secondaryOrange,
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

  static Widget _buildInfo(BuildContext context, IconData icon, String title, String value, Color color) {
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
              '$title: $value',
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

  static Future<void> _showImagePreview(
    BuildContext context,
    Uint8List imageBytes,
    String titulo,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Stack(
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
