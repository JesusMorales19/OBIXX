import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../../services/format_service.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_dropdown.dart';

class SueldoModal {
  static void mostrar(
    BuildContext context, {
    required Map<String, dynamic> trabajador,
    required int idTrabajo,
    required String emailContratista,
  }) {
    final tipoPeriodoController = TextEditingController(
      text: trabajador['tipo_periodo']?.toString() ?? 'semanal',
    );
    final montoController = TextEditingController(
      text: trabajador['monto_periodo']?.toString() ?? '',
    );
    final horasController = TextEditingController(
      text: trabajador['horas_requeridas_periodo']?.toString() ?? '48',
    );
    String tipoPeriodo = trabajador['tipo_periodo']?.toString() ?? 'semanal';
    String moneda = trabajador['moneda']?.toString() ?? 'MXN';

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
                height: MediaQuery.of(modalContext).size.height * 0.4,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 100, bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurar Sueldo - ${trabajador['nombre']} ${trabajador['apellido']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomDropdown<String>(
                          label: 'Tipo de Período',
                          icon: Icons.calendar_today,
                          value: tipoPeriodo,
                          items: const ['semanal', 'quincenal'],
                          itemBuilder: (value) => value == 'semanal' ? 'Semanal' : 'Quincenal',
                          onChanged: (value) {
                            setModalState(() {
                              tipoPeriodo = value ?? 'semanal';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: montoController,
                                label: 'Monto por Período',
                                icon: Icons.attach_money,
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomDropdown<String>(
                                label: 'Moneda',
                                icon: Icons.attach_money,
                                value: moneda,
                                items: const ['MXN', 'USD'],
                                onChanged: (value) {
                                  setModalState(() {
                                    moneda = value ?? 'MXN';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: horasController,
                          label: 'Horas Requeridas por Período',
                          icon: Icons.access_time,
                          hint: '48',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final monto = FormatService.parseDouble(montoController.text);
                              final horas = FormatService.parseDouble(horasController.text);

                              if (monto <= 0) {
                                CustomNotification.showError(
                                  context,
                                  'Ingresa un monto válido',
                                );
                                return;
                              }

                              final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                                call: () => ApiService.configurarSueldo(
                                  idAsignacion: trabajador['id_asignacion'],
                                  idTrabajoLargo: idTrabajo,
                                  emailTrabajador: trabajador['email_trabajador'],
                                  emailContratista: emailContratista,
                                  tipoPeriodo: tipoPeriodo,
                                  montoPeriodo: monto,
                                  moneda: moneda,
                                  horasRequeridasPeriodo: horas,
                                ),
                                errorMessage: 'Error al configurar sueldo',
                              );

                              if (result['success'] == true) {
                                Navigator.of(modalContext).pop();
                                CustomNotification.showSuccess(
                                  context,
                                  'Sueldo configurado exitosamente',
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
                              'Guardar',
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

