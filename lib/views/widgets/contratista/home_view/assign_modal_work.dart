import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/format_service.dart';
import '../../../../models/asignacion_trabajo_model.dart';
import '../../custom_notification.dart';

class AsignarTrabajoModal extends StatefulWidget {
  final String trabajadorNombre;
  final String trabajadorCategoria;
  final String emailTrabajador;
  final VoidCallback onAssignmentCompleted;
  final BuildContext parentContext;

  const AsignarTrabajoModal({
    super.key,
    required this.parentContext,
    required this.trabajadorNombre,
    required this.trabajadorCategoria,
    required this.emailTrabajador,
    required this.onAssignmentCompleted,
  });

  @override
  State<AsignarTrabajoModal> createState() => _AsignarTrabajoModalState();
}

class _AsignarTrabajoModalState extends State<AsignarTrabajoModal> {
  String selectedCategory = 'Corto plazo';
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  String? _emailContratista;
  List<Map<String, dynamic>> _trabajosCorto = [];
  List<Map<String, dynamic>> _trabajosLargo = [];

  @override
  void initState() {
    super.initState();
    _cargarTrabajos();
  }

  Future<void> _cargarTrabajos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await StorageService.getUser();
      final emailContratista = user?['email']?.toString();

      if (emailContratista == null || emailContratista.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No se encontró la sesión del contratista.';
        });
        return;
      }

      final resultados = await Future.wait([
        ApiService.obtenerTrabajosContratista(emailContratista),
        ApiService.obtenerTrabajosCortoContratista(emailContratista),
      ]);

      final resultadoLargo = resultados[0];
      final resultadoCorto = resultados[1];

      final List<Map<String, dynamic>> trabajosLargo = [];
      final List<Map<String, dynamic>> trabajosCorto = [];

      if (resultadoLargo['success'] == true) {
        final lista = (resultadoLargo['trabajos'] ?? []) as List<dynamic>;
        for (final t in lista) {
          final vacantes = t['vacantes_disponibles'] ?? 0;
          if (vacantes == null || (vacantes is num && vacantes <= 0)) {
            continue;
          }
          trabajosLargo.add({
            'id': t['id_trabajo_largo'],
            'titulo': t['titulo'] ?? 'Sin título',
            'vacantes': FormatService.parseInt(vacantes),
          });
        }
      }

      if (resultadoCorto['success'] == true) {
        final lista = (resultadoCorto['trabajos'] ?? []) as List<dynamic>;
        for (final t in lista) {
          final vacantes = t['vacantes_disponibles'] ?? 0;
          if (vacantes is num && vacantes <= 0) {
            continue;
          }
          trabajosCorto.add({
            'id': t['id_trabajo_corto'],
            'titulo': t['titulo'] ?? 'Sin título',
            'rangoPrecio': t['rango_pago'] ?? 'No especificado',
            'disponibilidad': t['disponibilidad'] ?? 'No especificada',
            'especialidad': t['especialidad'] ?? 'No especificada',
            'vacantes': FormatService.parseInt(vacantes),
          });
        }
      }

      final categoriaTrabajador = widget.trabajadorCategoria.toLowerCase();
      final filtradosCorto = trabajosCorto.where((trabajo) {
        final especialidad = (trabajo['especialidad'] ?? '').toString().toLowerCase();
        if (categoriaTrabajador.isEmpty) {
          return true;
        }
        return especialidad.contains(categoriaTrabajador);
      }).toList();

      if (!mounted) return;
      setState(() {
        _emailContratista = emailContratista;
        _trabajosLargo = trabajosLargo;
        _trabajosCorto = filtradosCorto;
        _isLoading = false;
        if (resultadoLargo['success'] != true && resultadoCorto['success'] != true) {
          _error = resultadoLargo['error']?.toString() ?? resultadoCorto['error']?.toString() ?? 'No se pudieron cargar los trabajos.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar trabajos: $e';
      });
    }
  }

  Future<void> _asignarTrabajo(Map<String, dynamic> trabajo) async {
    if (_emailContratista == null) {
      CustomNotification.showError(
        widget.parentContext,
        'No se encontró la sesión del contratista',
      );
      return;
    }

    final idTrabajo = trabajo['id'];
    if (idTrabajo == null) {
      CustomNotification.showError(
        widget.parentContext,
        'El trabajo seleccionado no es válido',
      );
      return;
    }

    int? parsedId;
    if (idTrabajo is int) {
      parsedId = idTrabajo;
    } else {
      parsedId = FormatService.parseInt(idTrabajo);
      if (parsedId == 0 && idTrabajo != null && idTrabajo != 0) {
        parsedId = null; // Si no se pudo parsear, mantener null
      }
    }

    if (parsedId == null) {
      CustomNotification.showError(
        widget.parentContext,
        'El identificador del trabajo no es válido',
      );
      return;
    }

    final tipoTrabajo = selectedCategory == 'Corto plazo' ? 'corto' : 'largo';

    setState(() {
      _isProcessing = true;
    });

    try {
      final asignacion = AsignacionTrabajoModel(
        emailContratista: _emailContratista!,
        emailTrabajador: widget.emailTrabajador,
        tipoTrabajo: tipoTrabajo,
        idTrabajo: parsedId,
      );

      final respuesta = await ApiService.asignarTrabajo(asignacion);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (respuesta['success'] == true) {
        CustomNotification.showSuccess(
          widget.parentContext,
          'Has asignado a ${widget.trabajadorNombre} a "${trabajo['titulo']}"',
        );
        widget.onAssignmentCompleted();
        Navigator.pop(context);
      } else {
        CustomNotification.showError(
          widget.parentContext,
          respuesta['error']?.toString() ?? 'No se pudo asignar el trabajo',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      CustomNotification.showError(
        widget.parentContext,
        'Error al asignar trabajo: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCortoPlazo = selectedCategory == 'Corto plazo';
    final trabajos = esCortoPlazo ? _trabajosCorto : _trabajosLargo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Asignar a ${widget.trabajadorNombre}',
              style: const TextStyle(
                color: Color(0xFF1F4E79),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Corto plazo', 'Largo plazo'].map((cat) {
                final bool isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: const Color(0xFFE67E22).withOpacity(0.2),
                    labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFE67E22) : Colors.black87,
                        fontWeight: FontWeight.bold),
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: LinearProgressIndicator(),
              ),
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        )
                      : trabajos.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  esCortoPlazo
                                      ? 'No tienes trabajos de corto plazo para la especialidad "${widget.trabajadorCategoria}".'
                                      : 'No tienes trabajos de largo plazo registrados.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: trabajos.length,
                              itemBuilder: (context, index) {
                                final trabajo = trabajos[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 3,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    title: Text(
                                      trabajo['titulo'] ?? 'Sin título',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F4E79),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (esCortoPlazo) ...[
                                          Text(
                                            '${trabajo['rangoPrecio'] ?? 'Rango no disponible'} • ${trabajo['disponibilidad'] ?? 'Disponibilidad no especificada'}',
                                          ),
                                          Text('Especialidad: ${trabajo['especialidad'] ?? 'No especificada'}'),
                                          Text('Vacantes disponibles: ${trabajo['vacantes'] ?? 0}'),
                                        ] else ...[
                                          Text('Vacantes disponibles: ${trabajo['vacantes'] ?? 0}'),
                                        ],
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: _isProcessing
                                          ? null
                                          : () => _asignarTrabajo(trabajo),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF5B400),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Asignar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

void showAsignarTrabajoModal({
  required BuildContext context,
  required String nombreTrabajador,
  required String categoriaTrabajador,
  required String emailTrabajador,
  required VoidCallback onAssignmentCompleted,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AsignarTrabajoModal(
      parentContext: context,
      trabajadorNombre: nombreTrabajador,
      trabajadorCategoria: categoriaTrabajador,
      emailTrabajador: emailTrabajador,
      onAssignmentCompleted: onAssignmentCompleted,
    ),
  );
}
