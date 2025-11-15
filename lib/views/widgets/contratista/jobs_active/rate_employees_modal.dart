import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/format_service.dart';
import '../../custom_notification.dart';
import '../../common/custom_text_field.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre.isEmpty ? email : nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              especialidad,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 6),
            _buildStars(idAsignacion),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
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
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Calificar trabajadores',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 12),
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
                height: 320,
                child: SingleChildScrollView(
                  child: Column(
                    children: trabajadores
                        .map((t) => _buildEmployeeTile(t))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    trabajadores.isEmpty || _isSubmitting ? null : _enviarCalificaciones,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF1F4E79),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Calificar y finalizar',
                        style: TextStyle(
                          fontSize: 16,
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
