import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/format_service.dart';
import '../../custom_notification.dart';
import '../../common/custom_text_field.dart';
import '../../../../core/utils/responsive.dart';

class RateEmployeesModal extends StatefulWidget {
  final BuildContext parentContext;
  final List<Map<String, dynamic>> trabajadores;
  final String emailContratista;
  final String tipoTrabajo;
  final int idTrabajo;
  final Future<void> Function()? onCompleted;

  const RateEmployeesModal({
    super.key,
    required this.parentContext,
    required this.trabajadores,
    required this.emailContratista,
    required this.tipoTrabajo,
    required this.idTrabajo,
    this.onCompleted,
  });

  @override
  State<RateEmployeesModal> createState() => _RateEmployeesModalState();
}

class _RateEmployeesModalState extends State<RateEmployeesModal> {
  final Map<int, int> _ratings = {};
  final Map<int, TextEditingController> _reviewControllers = {};
  final int _maxChars = 150;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final trabajador in widget.trabajadores) {
      final idAsignacion = _parseId(trabajador['id_asignacion']);
      if (idAsignacion != null) {
        _ratings[idAsignacion] = 5;
        _reviewControllers[idAsignacion] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _reviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final parsed = FormatService.parseInt(value);
    return parsed != 0 || value == 0 ? parsed : null;
  }

  Widget _buildStars(int idAsignacion) {
    final current = _ratings[idAsignacion] ?? 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < current ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _ratings[idAsignacion] = index + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> trabajador) {
    final idAsignacion = _parseId(trabajador['id_asignacion']);
    if (idAsignacion == null || !_reviewControllers.containsKey(idAsignacion)) {
      return const SizedBox.shrink();
    }

    final nombre = [
      (trabajador['nombre'] ?? '').toString().trim(),
      (trabajador['apellido'] ?? '').toString().trim(),
    ].where((p) => p.isNotEmpty).join(' ');
    final especialidad = (trabajador['categoria'] ?? 'Sin especialidad').toString();
    final email = (trabajador['email_trabajador'] ?? '').toString();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(
        vertical: Responsive.getResponsiveSpacing(
          context,
          mobile: 6,
          tablet: 7,
          desktop: 8,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          Responsive.getResponsiveSpacing(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre.isEmpty ? email : nombre,
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 17,
                  desktop: 18,
                ),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F4E79),
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 3,
                tablet: 3.5,
                desktop: 4,
              ),
            ),
            Text(
              especialidad,
              style: TextStyle(
                color: Colors.black87,
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 5,
                tablet: 5.5,
                desktop: 6,
              ),
            ),
            _buildStars(idAsignacion),
            if (email.isNotEmpty) ...[
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 3,
                  tablet: 3.5,
                  desktop: 4,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 11,
                    tablet: 11.5,
                    desktop: 12,
                  ),
                ),
              ),
            ],
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
            ),
            CustomTextField(
              controller: _reviewControllers[idAsignacion]!,
              label: 'Reseña (opcional)',
              icon: Icons.rate_review,
              hint: 'Escribe una reseña',
              maxLines: 3,
              validator: null, // Opcional, no requiere validación
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarCalificaciones() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> calificaciones = [];

      for (final trabajador in widget.trabajadores) {
        final idAsignacion = _parseId(trabajador['id_asignacion']);
        final emailTrabajador = (trabajador['email_trabajador'] ?? '').toString();
        if (idAsignacion == null || emailTrabajador.isEmpty) {
          continue;
        }

        final estrellas = _ratings[idAsignacion] ?? 5;
        final resena = _reviewControllers[idAsignacion]?.text.trim();

        calificaciones.add({
          'idAsignacion': idAsignacion,
          'emailTrabajador': emailTrabajador,
          'estrellas': estrellas,
          'resena': (resena == null || resena.isEmpty) ? null : resena,
        });
      }

      if (calificaciones.isEmpty) {
        CustomNotification.showError(
          widget.parentContext,
          'No se encontraron trabajadores válidos para calificar.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final response = await ApiService.finalizarTrabajo(
        emailContratista: widget.emailContratista,
        tipoTrabajo: widget.tipoTrabajo,
        idTrabajo: widget.idTrabajo,
        calificaciones: calificaciones,
      );

      if (response['success'] == true) {
        Navigator.of(context).pop();

        if (widget.onCompleted != null) {
          await widget.onCompleted!();
        }

        CustomNotification.showSuccess(
          widget.parentContext,
          'Trabajo finalizado y calificaciones registradas correctamente.',
        );
      } else {
        final error = response['error'] ?? 'No se pudo finalizar el trabajo.';
        CustomNotification.showError(widget.parentContext, error);
        setState(() => _isSubmitting = false);
      }
    } catch (error) {
      CustomNotification.showError(
        widget.parentContext,
        'Error al finalizar el trabajo: $error',
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trabajadores = widget.trabajadores
        .where((t) => _parseId(t['id_asignacion']) != null)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 14,
          desktop: 16,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(
          Responsive.getResponsiveSpacing(
            context,
            mobile: 14,
            tablet: 16,
            desktop: 18,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Calificar trabajadores',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F4E79),
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
            ),
            if (trabajadores.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No hay trabajadores por calificar.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 280,
                  tablet: 300,
                  desktop: 320,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: trabajadores
                        .map((t) => _buildEmployeeTile(t))
                        .toList(),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    trabajadores.isEmpty || _isSubmitting ? null : _enviarCalificaciones,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF1F4E79),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 21,
                          desktop: 22,
                        ),
                        height: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 21,
                          desktop: 22,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Calificar y finalizar',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
