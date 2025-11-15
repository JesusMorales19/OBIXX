import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../../services/format_service.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_dropdown.dart';

class HorasModal {
  static void mostrar(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
  }) {
    _mostrarFormularioHoras(context, idTrabajo, emailContratista);
  }

  static void _mostrarFormularioHoras(
    BuildContext context,
    int idTrabajo,
    String emailContratista,
  ) async {
    // Obtener trabajadores primero
    final trabajadoresResult = await ApiService.obtenerTrabajadoresTrabajo(
      idTrabajoLargo: idTrabajo,
      emailContratista: emailContratista,
    );

    if (trabajadoresResult['success'] != true) {
      CustomNotification.showError(context, 'Error al cargar trabajadores');
      return;
    }

    final trabajadores = List<Map<String, dynamic>>.from(
      trabajadoresResult['trabajadores'] ?? [],
    );

    if (trabajadores.isEmpty) {
      CustomNotification.showError(context, 'No hay trabajadores asignados');
      return;
    }

    int? idAsignacionSeleccionada;
    String? emailTrabajadorSeleccionado;
    final fechaController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final horasController = TextEditingController();
    final minutosController = TextEditingController();
    final notaController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                height: MediaQuery.of(modalContext).size.height * 0.5,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registrar Horas Laborales',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomDropdown<int>(
                          label: 'Seleccionar Trabajador',
                          icon: Icons.person,
                          value: idAsignacionSeleccionada,
                          items: trabajadores.map((t) => t['id_asignacion'] as int).toList(),
                          itemBuilder: (id) {
                            final trabajador = trabajadores.firstWhere(
                              (t) => t['id_asignacion'] == id,
                            );
                            return '${trabajador['nombre']} ${trabajador['apellido']}';
                          },
                          onChanged: (value) {
                            setModalState(() {
                              idAsignacionSeleccionada = value;
                              final trabajador = trabajadores.firstWhere(
                                (t) => t['id_asignacion'] == value,
                              );
                              emailTrabajadorSeleccionado = trabajador['email_trabajador'];
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: fechaController,
                          label: 'Fecha',
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: horasController,
                                label: 'Horas',
                                icon: Icons.access_time,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: minutosController,
                                label: 'Minutos',
                                icon: Icons.timer,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: notaController,
                          label: 'Nota (opcional)',
                          icon: Icons.note,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (idAsignacionSeleccionada == null || emailTrabajadorSeleccionado == null) {
                                CustomNotification.showError(
                                  context,
                                  'Selecciona un trabajador',
                                );
                                return;
                              }

                              final horas = FormatService.parseDouble(horasController.text);
                              if (horas <= 0) {
                                CustomNotification.showError(
                                  context,
                                  'Ingresa horas válidas',
                                );
                                return;
                              }

                              final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                                call: () => ApiService.registrarHoras(
                                  idAsignacion: idAsignacionSeleccionada!,
                                  emailTrabajador: emailTrabajadorSeleccionado!,
                                  emailContratista: emailContratista,
                                  fecha: fechaController.text,
                                  horas: horas,
                                  minutos: FormatService.parseDoubleNullable(minutosController.text),
                                  nota: notaController.text.isEmpty ? null : notaController.text,
                                ),
                                errorMessage: 'Error al registrar horas',
                              );

                              if (result['success'] == true) {
                                Navigator.of(modalContext).pop();
                                CustomNotification.showSuccess(
                                  context,
                                  'Horas registradas exitosamente',
                                );
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
                              'Registrar',
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
      },
    );
  }
}

