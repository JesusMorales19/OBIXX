import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../widgets/custom_notification.dart';
import '../../common/custom_text_field.dart';

class _CalificarTrabajadorModal extends StatefulWidget {
  final String nombre;
  final String emailContratista;
  final String emailTrabajador;
  final int idAsignacion;
  final BuildContext parentContext;
  final Future<void> Function()? onCompleted;

  const _CalificarTrabajadorModal({
    required this.nombre,
    required this.emailContratista,
    required this.emailTrabajador,
    required this.idAsignacion,
    required this.parentContext,
    this.onCompleted,
  });

  @override
  State<_CalificarTrabajadorModal> createState() => _CalificarTrabajadorModalState();
}

class _CalificarTrabajadorModalState extends State<_CalificarTrabajadorModal> {
  int calificacion = 0;
  bool isSubmitting = false;
  late final TextEditingController reviewsController;

  @override
  void initState() {
    super.initState();
    reviewsController = TextEditingController();
  }

  @override
  void dispose() {
    reviewsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 140),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Califica a ${widget.nombre}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    color: Colors.black
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          calificacion = index + 1;
                        });
                      },
                      icon: Icon(
                        Icons.star,
                        size: 36,
                        color: index < calificacion ? Colors.amber : Colors.white54,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  controller: reviewsController,
                  label: 'Reseña (opcional)',
                  icon: Icons.rate_review,
                  hint: 'Escribe una reseña',
                  maxLines: 3,
                  validator: null, // Opcional, no requiere validación
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (calificacion == 0) {
                            CustomNotification.showError(
                              widget.parentContext,
                              'Selecciona una calificación antes de enviar.',
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          final response = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                            call: () => ApiService.registrarCalificacionTrabajador(
                              emailContratista: widget.emailContratista,
                              emailTrabajador: widget.emailTrabajador,
                              idAsignacion: widget.idAsignacion,
                              estrellas: calificacion,
                              resena: reviewsController.text.trim().isEmpty
                                  ? null
                                  : reviewsController.text.trim(),
                            ),
                            errorMessage: 'Error al registrar la calificación',
                            showError: false,
                          );

                          if (response['success'] != true) {
                            final error = response['error']?.toString() ?? 'No se pudo registrar la calificación.';
                            if (widget.parentContext.mounted) {
                              CustomNotification.showError(widget.parentContext, error);
                            }
                            if (mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                            return;
                          }

                          final apiResponse = response['data'] as Map<String, dynamic>?;
                          if (apiResponse?['success'] != true) {
                            final error = apiResponse?['error']?.toString() ?? 'No se pudo registrar la calificación.';
                            if (widget.parentContext.mounted) {
                              CustomNotification.showError(widget.parentContext, error);
                            }
                            if (mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                            return;
                          }

                          final cancelResponse = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                            call: () => ApiService.cancelarAsignacion(
                              emailContratista: widget.emailContratista,
                              emailTrabajador: widget.emailTrabajador,
                            ),
                            errorMessage: 'Error al cancelar la asignación',
                            showError: false,
                          );

                          if (cancelResponse['success'] != true) {
                            final error = cancelResponse['error']?.toString() ?? 'No se pudo cancelar la asignación.';
                            if (widget.parentContext.mounted) {
                              CustomNotification.showError(widget.parentContext, error);
                            }
                            if (mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                            return;
                          }

                          final cancelApiResponse = cancelResponse['data'] as Map<String, dynamic>?;
                          if (cancelApiResponse?['success'] != true) {
                            final error = cancelApiResponse?['error']?.toString() ?? 'No se pudo cancelar la asignación.';
                            if (widget.parentContext.mounted) {
                              CustomNotification.showError(widget.parentContext, error);
                            }
                            if (mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                            return;
                          }

                          if (widget.onCompleted != null) {
                            await widget.onCompleted!();
                          }

                          if (mounted) {
                            Navigator.pop(context);
                          }
                          
                          if (widget.parentContext.mounted) {
                            CustomNotification.showSuccess(
                              widget.parentContext,
                              'Calificación enviada y trabajador desvinculado correctamente.',
                            );
                          }
                          
                          if (mounted) {
                            setState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    backgroundColor: Color(0xFF1F4E79),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Enviar",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                )
              ],
            ),
          ),
        );
  }
}

void showCalificarTrabajadorModal(
  BuildContext context, {
  required BuildContext parentContext,
  required String nombre,
  required String emailContratista,
  required String emailTrabajador,
  required int idAsignacion,
  Future<void> Function()? onCompleted,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return _CalificarTrabajadorModal(
        nombre: nombre,
        emailContratista: emailContratista,
        emailTrabajador: emailTrabajador,
        idAsignacion: idAsignacion,
        parentContext: parentContext,
        onCompleted: onCompleted,
      );
    },
  );
}
