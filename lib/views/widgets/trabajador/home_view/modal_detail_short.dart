import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

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
              initialChildSize: 0.78, // 👈 más bajo por defecto
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
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 18),
                      if (contratistaNombre != null && contratistaNombre.isNotEmpty)
                        _buildInfo(Icons.person, 'Contratista', contratistaNombre, primaryYellow),
                      _buildInfo(Icons.attach_money, 'Rango de precio', rangoPrecio, primaryYellow),
                      _buildInfo(Icons.access_time, 'Disponibilidad', disponibilidad, primaryYellow),
                      _buildInfo(Icons.build, 'Especialidad requerida', especialidad, secondaryOrange),

                      const SizedBox(height: 18),
                      const Text(
                        'Fotos del trabajo:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      fotos.isEmpty
                          ? const Text(
                              'No se proporcionaron imágenes para este trabajo.',
                              style: TextStyle(color: Colors.grey),
                            )
                          : SizedBox(
                              height: 110,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: fotos.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                                          width: 150,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    return Container(
                                      width: 150,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('Imagen inválida'),
                                    );
                                  }
                                },
                              ),
                            ),

                      const SizedBox(height: 25),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryOrange,
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

  static Widget _buildInfo(IconData icon, String title, String value, Color color) {
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
              '$title: $value',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
