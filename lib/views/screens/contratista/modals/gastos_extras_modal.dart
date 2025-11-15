import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../../services/format_service.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/loading_button.dart';

class GastosExtrasModal {
  static void mostrar(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
    VoidCallback? onGuardado,
  }) {
    final fechaController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final montoController = TextEditingController();
    final descripcionController = TextEditingController();
    final isLoadingNotifier = ValueNotifier<bool>(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                height: MediaQuery.of(modalContext).size.height * 0.4,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 100, bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registrar Gasto Extra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: fechaController,
                          label: 'Fecha del Gasto',
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              fechaController.text = DateFormat('yyyy-MM-dd').format(fecha);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: montoController,
                          label: 'Monto',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: descripcionController,
                          label: 'Descripción (ej: Cemento, Herramientas, etc.)',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<bool>(
                          valueListenable: isLoadingNotifier,
                          builder: (context, isLoading, child) {
                            return LoadingButton(
                              onPressed: () async {
                                if (fechaController.text.isEmpty ||
                                    montoController.text.isEmpty ||
                                    descripcionController.text.isEmpty) {
                                  CustomNotification.showError(
                                    context,
                                    'Por favor completa todos los campos',
                                  );
                                  return;
                                }

                                final monto = FormatService.parseDouble(montoController.text);
                                if (monto <= 0) {
                                  CustomNotification.showError(
                                    context,
                                    'El monto debe ser un número válido mayor a 0',
                                  );
                                  return;
                                }

                                isLoadingNotifier.value = true;

                                final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                                  call: () => ApiService.registrarGastoExtra(
                                    idTrabajoLargo: idTrabajo,
                                    emailContratista: emailContratista,
                                    fechaGasto: fechaController.text,
                                    monto: monto,
                                    descripcion: descripcionController.text,
                                  ),
                                  errorMessage: 'Error al registrar gasto extra',
                                );

                                isLoadingNotifier.value = false;

                                if (result['success'] == true) {
                                  Navigator.of(modalContext).pop();
                                  CustomNotification.showSuccess(
                                    context,
                                    'Gasto extra registrado exitosamente',
                                  );
                                  if (onGuardado != null) {
                                    onGuardado();
                                  }
                                }
                              },
                              label: 'Registrar Gasto',
                              icon: Icons.add_circle_outline,
                              isLoading: isLoading,
                              backgroundColor: const Color(0xFF1F4E79),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              borderRadius: BorderRadius.circular(12),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              loadingText: 'Registrando...',
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

