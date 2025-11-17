import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_wrapper.dart';
import '../../../../services/format_service.dart';
import '../../../widgets/custom_notification.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_dropdown.dart';
import '../../../../core/utils/responsive.dart';

class PresupuestoModal {
  static void mostrar(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
    dynamic presupuestoActual,
    required VoidCallback onGuardado,
  }) {
    String presupuestoTexto = '';
    if (presupuestoActual != null) {
      final valor = FormatService.parseDouble(presupuestoActual);
      presupuestoTexto = FormatService.formatNumber(valor);
    }
    final controller = TextEditingController(text: presupuestoTexto);
    final monedaNotifier = ValueNotifier<String>('MXN');
    
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
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalContext).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: Responsive.getHorizontalPadding(context),
                      right: Responsive.getHorizontalPadding(context),
                      top: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 20,
                        tablet: 24,
                        desktop: 28,
                      ),
                      bottom: MediaQuery.of(modalContext).padding.bottom + Responsive.getResponsiveSpacing(
                        context,
                        mobile: 20,
                        tablet: 24,
                        desktop: 28,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'Registrar Presupuesto',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 6,
                          tablet: 7,
                          desktop: 8,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: controller,
                              label: 'Presupuesto',
                              icon: Icons.attach_money,
                              hint: '0.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 10,
                              desktop: 12,
                            ),
                          ),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: monedaNotifier,
                              builder: (context, moneda, child) {
                                return CustomDropdown<String>(
                                  label: 'Moneda',
                                  icon: Icons.attach_money,
                                  value: moneda,
                                  items: const ['MXN', 'USD'],
                                  onChanged: (value) {
                                    monedaNotifier.value = value ?? 'MXN';
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final presupuesto = FormatService.parseDouble(controller.text);
                            if (presupuesto <= 0) {
                              CustomNotification.showError(
                                context,
                                'Ingresa un presupuesto válido',
                              );
                              return;
                            }

                            final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                              call: () => ApiService.registrarPresupuesto(
                                emailContratista: emailContratista,
                                idTrabajoLargo: idTrabajo,
                                presupuesto: presupuesto,
                                moneda: monedaNotifier.value,
                              ),
                              errorMessage: 'Error al registrar presupuesto',
                            );

                            if (result['success'] == true) {
                              Navigator.of(modalContext).pop();
                              CustomNotification.showSuccess(
                                context,
                                'Presupuesto registrado exitosamente',
                              );
                              onGuardado();
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
                    ],
                  ),
                ),
              ),
            ),);
          },
        );
      },
    );
  }
}

