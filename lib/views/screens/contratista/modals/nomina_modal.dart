import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/common/custom_text_field.dart';
import 'premium_modal_helpers.dart';

class NominaModal {
  static void mostrar(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
  }) {
    final periodoInicioController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(const Duration(days: 7)),
      ),
    );
    final periodoFinController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).padding.bottom + MediaQuery.of(modalContext).viewInsets.bottom,
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
                      'Generar Nómina',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: periodoInicioController,
                      label: 'Fecha Inicio',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 7)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          periodoInicioController.text = DateFormat('yyyy-MM-dd').format(fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: periodoFinController,
                      label: 'Fecha Fin',
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
                          periodoFinController.text = DateFormat('yyyy-MM-dd').format(fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                            call: () => ApiService.generarNomina(
                              idTrabajoLargo: idTrabajo,
                              emailContratista: emailContratista,
                              periodoInicio: periodoInicioController.text,
                              periodoFin: periodoFinController.text,
                            ),
                            errorMessage: 'Error al generar nómina',
                          );

                          // El resultado viene envuelto: result['data'] contiene la respuesta de _postRequest
                          // que a su vez tiene 'data' con la respuesta real del backend
                          if (result['success'] == true && result['data'] != null) {
                            final apiResponse = result['data'] as Map<String, dynamic>;
                            
                            // Verificar si la respuesta del API fue exitosa
                            if (apiResponse['success'] == true && apiResponse['data'] != null) {
                              final data = apiResponse['data'] as Map<String, dynamic>;
                              
                              Navigator.of(modalContext).pop();
                              final nomina = data['nomina'] as Map<String, dynamic>?;
                              final detalle = data['detalle'] as List<dynamic>?;
                              final gastosExtras = data['gastos_extras'] as List<dynamic>?;
                              final totalGastosExtras = data['total_gastos_extras'] as num?;
                              final mensaje = data['mensaje'] as String?;
                              final pdfBase64 = data['pdf_base64'] as String?;
                              
                              if (nomina == null) {
                                CustomNotification.showError(
                                  context,
                                  'Error: No se pudo generar la nómina',
                                );
                                return;
                              }
                              
                              // Mostrar mensaje informativo si existe
                              if (mensaje != null) {
                                CustomNotification.showInfo(context, mensaje);
                              }
                              
                              // Mostrar mensaje de éxito
                              CustomNotification.showSuccess(
                                context,
                                'La nómina ha sido generada exitosamente',
                              );
                              
                              // Mostrar resumen de nómina
                              PremiumModalHelpers.mostrarResumenNomina(context, nomina, detalle ?? [], gastosExtras ?? [], totalGastosExtras, pdfBase64);
                            } else {
                              // Si la respuesta del API no fue exitosa, mostrar el error
                              final errorMsg = apiResponse['error']?.toString() ?? 'Error desconocido al generar la nómina';
                              CustomNotification.showError(
                                context,
                                errorMsg,
                              );
                            }
                          } else {
                            // Si ApiWrapper falló, ya mostró el error automáticamente
                            // Pero podemos cerrar el modal si está abierto
                            if (modalContext.mounted) {
                              Navigator.of(modalContext).pop();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4E79),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Generar Nómina',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

