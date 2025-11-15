import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_service.dart';
import '../../../../services/format_service.dart';
import '../../custom_notification.dart';
import 'confirm_dismiss_modal.dart';

void showModalTrabajadores(
  BuildContext context, {
  required String emailContratista,
  required String tipoTrabajo,
  required int idTrabajo,
}) {
  final BuildContext parentContext = context;
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      List<Map<String, dynamic>> trabajadores = [];
      bool isLoading = true;
      String? errorMessage;
      bool initialized = false;
      final dateFormat = DateFormat('yyyy-MM-dd');

      Future<void> cargarDatos(StateSetter innerSetState) async {
        innerSetState(() {
          isLoading = true;
          errorMessage = null;
        });

        try {
          final response = await ApiService.obtenerTrabajadoresAsignados(
            emailContratista: emailContratista,
            tipoTrabajo: tipoTrabajo,
            idTrabajo: idTrabajo,
          );

          if (response['success'] == true) {
            final data = response['trabajadores'] as List<dynamic>;
            trabajadores = data
                .map((worker) {
                  final map = Map<String, dynamic>.from(worker as Map<String, dynamic>);
                  map['es_favorito'] = map['es_favorito'] == true;
                  map['favoritoLoading'] = false;
                  return map;
                })
                .toList();
            innerSetState(() {
              isLoading = false;
            });
          } else {
            innerSetState(() {
              isLoading = false;
              errorMessage = response['error'] ?? 'No fue posible obtener los trabajadores.';
            });
          }
        } catch (error) {
          innerSetState(() {
            isLoading = false;
            errorMessage = 'Error al cargar trabajadores: $error';
          });
        }
      }

      Future<void> toggleFavorito(StateSetter innerSetState, int index) async {
        if (index < 0 || index >= trabajadores.length) return;

        final trabajador = trabajadores[index];
        final emailTrabajador = trabajador['email_trabajador']?.toString();
        if (emailTrabajador == null || emailTrabajador.isEmpty) {
          CustomNotification.showError(
            parentContext,
            'No se encontró el email del trabajador.',
          );
          return;
        }

        final esFavoritoActual = trabajador['es_favorito'] == true;

        innerSetState(() {
          trabajadores[index]['favoritoLoading'] = true;
        });

        try {
          Map<String, dynamic> response;
          if (esFavoritoActual) {
            response = await ApiService.quitarFavorito(emailContratista, emailTrabajador);
          } else {
            response = await ApiService.agregarFavorito(emailContratista, emailTrabajador);
          }

          if (response['success'] == true) {
            innerSetState(() {
              trabajadores[index]['es_favorito'] = !esFavoritoActual;
            });

            CustomNotification.showSuccess(
              parentContext,
              esFavoritoActual
                  ? 'Trabajador eliminado de favoritos'
                  : 'Trabajador agregado a favoritos',
            );
          } else {
            final error = response['error'] ?? 'No se pudo actualizar el favorito.';
            CustomNotification.showError(
              parentContext,
              error,
            );
          }
        } catch (error) {
          CustomNotification.showError(
            parentContext,
            'Error al actualizar favorito: $error',
          );
        } finally {
          innerSetState(() {
            trabajadores[index]['favoritoLoading'] = false;
          });
        }
      }

      String _formatDate(dynamic value) {
        if (value == null) return 'Sin fecha';
        final text = value.toString();
        final parsed = DateTime.tryParse(text);
        if (parsed == null) return text;
        return dateFormat.format(parsed);
      }

      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Center(
            child: StatefulBuilder(
              builder: (context, innerSetState) {
                if (!initialized) {
                  initialized = true;
                  Future.microtask(() => cargarDatos(innerSetState));
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white, width: .5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 147, 222, 252).withOpacity(0.8),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Trabajadores asignados',
                                style: TextStyle(
                                  color: Color(0xFF1F4E79),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Actualizar lista',
                                    onPressed: () => cargarDatos(innerSetState),
                                    icon: const Icon(Icons.refresh, color: Color(0xFF1F4E79)),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.black,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (isLoading)
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (errorMessage != null)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => cargarDatos(innerSetState),
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            )
                          else if (trabajadores.isEmpty)
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Aún no hay trabajadores asignados a este trabajo.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: trabajadores.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 15),
                                itemBuilder: (context, index) {
                                  final trabajador = trabajadores[index];
                                  final nombre = '${trabajador['nombre'] ?? ''} ${trabajador['apellido'] ?? ''}'.trim();
                                  final especialidad = trabajador['categoria'] ?? 'Sin especialidad';
                                  final fechaAsignacion = _formatDate(trabajador['fecha_asignacion']);
                                  final esFavorito = trabajador['es_favorito'] == true;
                                  final favoritoLoading = trabajador['favoritoLoading'] == true;
                                  final emailTrabajador = trabajador['email_trabajador']?.toString() ?? '';
                                  final dynamic rawIdAsignacion = trabajador['id_asignacion'];
                                  final int? idAsignacion = rawIdAsignacion is int
                                      ? rawIdAsignacion
                                      : (rawIdAsignacion != null
                                          ? FormatService.parseInt(rawIdAsignacion)
                                          : null);

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9F9F9),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFE0E0E0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 15,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                _buildAvatar(
                                                  fotoPerfil: trabajador['foto_perfil'],
                                                  nombre: nombre,
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        nombre.isEmpty ? 'Nombre no disponible' : nombre,
                                                        style: const TextStyle(
                                                          color: Color(0xFF1F4E79),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        especialidad,
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Asignado: $fechaAsignacion',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (emailTrabajador.isEmpty || idAsignacion == null) {
                                                    CustomNotification.showError(
                                                      parentContext,
                                                      'No se pudo obtener la información del trabajador.',
                                                    );
                                                    return;
                                                  }

                                                  showConfirmarDespedirModal(
                                                    context,
                                                    nombre: nombre,
                                                    emailContratista: emailContratista,
                                                    emailTrabajador: emailTrabajador,
                                                    idAsignacion: idAsignacion,
                                                    parentContext: parentContext,
                                                    onCompleted: () async {
                                                      await cargarDatos(innerSetState);
                                                    },
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFFF9800),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  minimumSize: const Size.fromHeight(45),
                                                ),
                                                child: const Text('Desvincular'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: IconButton(
                                            tooltip: esFavorito
                                                ? 'Quitar de favoritos'
                                                : 'Agregar a favoritos',
                                            onPressed: favoritoLoading
                                                ? null
                                                : () => toggleFavorito(innerSetState, index),
                                            icon: favoritoLoading
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                                  )
                                                : esFavorito
                                                    ? ShaderMask(
                                                        shaderCallback: (Rect bounds) {
                                                          return const LinearGradient(
                                                            colors: [
                                                              Color(0xFFE67E22),
                                                              Color(0xFFF5B400),
                                                            ],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ).createShader(bounds);
                                                        },
                                                        child: const Icon(
                                                          Icons.favorite,
                                                          color: Colors.white,
                                                          size: 26,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.favorite_border,
                                                        color: Colors.grey,
                                                        size: 26,
                                                      ),
                                            splashRadius: 22,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildAvatar({required String? fotoPerfil, required String nombre}) {
  ImageProvider? imageProvider;
  
  if (fotoPerfil != null && fotoPerfil.isNotEmpty) {
    try {
      final cleaned = fotoPerfil.contains(',')
          ? fotoPerfil.split(',').last
          : fotoPerfil;
      final bytes = base64Decode(cleaned);
      imageProvider = MemoryImage(bytes);
    } catch (_) {
      imageProvider = null;
    }
  }

  return CircleAvatar(
    radius: 32,
    backgroundColor: imageProvider == null
        ? const Color(0xFFFFF3E0)
        : Colors.transparent,
    backgroundImage: imageProvider,
    child: imageProvider == null
        ? Text(
            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF1F4E79),
              fontWeight: FontWeight.bold,
            ),
          )
        : null,
  );
}
