import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/contratista/jobs_active/job_card_widgets.dart';
import '../../widgets/contratista/jobs_active/search_and_filter_bar_jobs.dart';
import '../../widgets/contratista/jobs_active/show_modal_employees.dart';
import '../../widgets/contratista/jobs_active/modals_helper.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../../services/api_wrapper.dart';


class JobsActive extends StatefulWidget {
  const JobsActive({super.key});

  @override
  State<JobsActive> createState() => _JobsActiveState();
}

class _JobsActiveState extends State<JobsActive> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  String? _emailContratista;
  late VoidCallback _userListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_filterJobs);
    _userListener = () {
      final user = StorageService.userNotifier.value;
      final nuevoEmail = user?['email']?.toString();
      if (nuevoEmail != null && nuevoEmail != _emailContratista) {
        _cargarTrabajosContratista();
      }
    };
    StorageService.userNotifier.addListener(_userListener);
    _cargarTrabajosContratista();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StorageService.userNotifier.removeListener(_userListener);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refrescar cuando la app vuelve al foreground
      _cargarTrabajosContratista();
    }
  }


  /// Cargar trabajos de largo plazo del contratista desde la API
  Future<void> _cargarTrabajosContratista() async {
    setState(() => _isLoading = true);

    final user = await StorageService.getUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final emailContratista = user['email'];

    final resultados = await ApiWrapper.safeCallMultiple<Map<String, dynamic>>(
      calls: [
        () => ApiService.obtenerTrabajosContratista(emailContratista),
        () => ApiService.obtenerTrabajosCortoContratista(emailContratista),
      ],
      errorMessage: 'Error al cargar trabajos',
      showError: false,
    );

    final resultadoLargo = resultados[0];
    final resultadoCorto = resultados[1];

    final List<Map<String, dynamic>> trabajosCombinados = [];

    if (resultadoLargo != null && resultadoLargo['success'] == true) {
      final trabajosLargos = resultadoLargo['trabajos'] as List<dynamic>;
      trabajosCombinados.addAll(trabajosLargos.map((t) {
        final vacantes = FormatService.parseInt(t['vacantes_disponibles']);
        return {
          'type': 'largo',
          'id': t['id_trabajo_largo'],
          'title': t['titulo'] ?? '',
          'descripcion': t['descripcion'] ?? '',
          'frecuenciaPago': t['frecuencia'] ?? 'No especificado',
          'vacantesDisponibles': vacantes.toString(),
          'vacantesInt': vacantes,
          'tipoObra': t['tipo_obra'] ?? 'No especificado',
          'fechaInicio': FormatService.formatDateFromIsoString(t['fecha_inicio']?.toString()),
          'fechaFinal': FormatService.formatDateFromIsoString(t['fecha_fin']?.toString()),
          'estado': t['estado'] ?? 'activo',
          'latitud': FormatService.parseDoubleNullable(t['latitud']),
          'longitud': FormatService.parseDoubleNullable(t['longitud']),
          'direccion': t['direccion'],
        };
      }));
    }

    if (resultadoCorto != null && resultadoCorto['success'] == true) {
      final trabajosCortos = resultadoCorto['trabajos'] as List<dynamic>;
      trabajosCombinados.addAll(trabajosCortos.map((t) {
        final vacantes = FormatService.parseInt(t['vacantes_disponibles']);
        return {
          'type': 'corto',
          'id': t['id_trabajo_corto'],
          'title': t['titulo'] ?? '',
          'descripcion': t['descripcion'] ?? '',
          'rangoPrecio': t['rango_pago'] ?? 'No especificado',
          'especialidad': t['especialidad'] ?? 'No especificado',
          'disponibilidad': t['disponibilidad'] ?? 'No especificada',
          'estado': t['estado'] ?? 'activo',
          'latitud': FormatService.parseDoubleNullable(t['latitud']),
          'longitud': FormatService.parseDoubleNullable(t['longitud']),
          'direccion': t['direccion'],
          'vacantesDisponibles': vacantes.toString(),
          'vacantesInt': vacantes,
          'fechaCreacion': FormatService.formatDateFromIsoString(t['created_at']?.toString()),
        };
      }));
    }

    setState(() {
      _emailContratista = emailContratista;
      _allJobs = trabajosCombinados;
      _filteredJobs = List.from(trabajosCombinados);
      _isLoading = false;
    });
  }

  void _filterJobs() {
     setState(() {
       final searchQuery = _searchController.text.toLowerCase().trim();

      final filtro = _selectedFilter;
 
       _filteredJobs = _allJobs.where((job) {
         if (filtro != null) {
          final estado = job['estado']?.toString().toLowerCase();

          if (filtro == 'largo' || filtro == 'corto') {
            if (job['type'] != filtro) {
              return false;
            }
            if (estado != null && estado != 'activo') {
              return false;
            }
          } else if (filtro == 'terminado') {
            const estadosTerminados = {'completado', 'finalizado'};
            if (!estadosTerminados.contains(estado)) {
              return false;
            }
          } else if (filtro == 'en_proceso') {
            const estadosProceso = {'pausado', 'en_proceso'};
            if (!estadosProceso.contains(estado)) {
              return false;
            }
          }
        }
 
         // Filtrar por nombre (título)
         if (searchQuery.isNotEmpty) {
           final title = job['title']?.toString().toLowerCase() ?? '';
           if (!title.contains(searchQuery)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _onFilterChanged(String? value) {
    setState(() {
      _selectedFilter = value;
    });
    _filterJobs();
  }

  Future<List<Map<String, dynamic>>> _obtenerTrabajadoresAsignados(
    String tipoTrabajo,
    int idTrabajo,
  ) async {
    if (_emailContratista == null) {
      throw Exception('No se pudo determinar el contratista actual.');
    }

    final response = await ApiWrapper.safeCall<Map<String, dynamic>>(
      call: () => ApiService.obtenerTrabajadoresAsignados(
        emailContratista: _emailContratista!,
        tipoTrabajo: tipoTrabajo,
        idTrabajo: idTrabajo,
      ),
      errorMessage: 'Error al obtener trabajadores asignados',
      showError: false,
    );

    if (response != null && response['success'] == true) {
      final data = response['trabajadores'] as List<dynamic>;
      return data
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(response?['error']?.toString() ?? 'Error al obtener trabajadores asignados');
  }

  void _mostrarTrabajadoresAsignados(
    BuildContext context, {
    required String tipoTrabajo,
    required int idTrabajo,
  }) {
    if (_emailContratista == null) {
      CustomNotification.showError(
        context,
        'No se encontró información del contratista.',
      );
      return;
    }

    showModalTrabajadores(
      context,
      emailContratista: _emailContratista!,
      tipoTrabajo: tipoTrabajo,
      idTrabajo: idTrabajo,
    );
  }

  Future<void> _mostrarFlujoTerminar(
    BuildContext context, {
    required String tipoTrabajo,
    required int idTrabajo,
  }) async {
    if (_emailContratista == null) {
      CustomNotification.showError(
        context,
        'No se encontró información del contratista.',
      );
      return;
    }

    try {
      final trabajadores =
          await _obtenerTrabajadoresAsignados(tipoTrabajo, idTrabajo);

      if (!mounted) return;

      if (trabajadores.isEmpty) {
        CustomNotification.showInfo(
          context,
          'No hay trabajadores asignados a este trabajo.',
        );
        return;
      }

      showEndJobFlow(
        context,
        parentContext: context,
        trabajadores: trabajadores,
        emailContratista: _emailContratista!,
        tipoTrabajo: tipoTrabajo,
        idTrabajo: idTrabajo,
        onCompleted: () async {
          await _cargarTrabajosContratista();
        },
      );
    } catch (error) {
      if (!mounted) return;
      CustomNotification.showError(
        context,
        'Error al obtener trabajadores: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(
        role: 'contratista',
        currentIndex: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(tipoUsuario: 'contratista'),
            const SizedBox(height: 10),

            // Línea con inner shadow debajo del título
            const DividerWithShadow(),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'Trabajos Activos',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Barra de búsqueda y selector
            SearchAndFilterBar(
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
              onSearchChanged: (_) => _filterJobs(),
            ),

            const SizedBox(height: 40),

            // Lista scrollable de trabajos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredJobs.isEmpty
                      ? const Center(
                          child: Text(
                            'No tienes trabajos registrados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: _filteredJobs.map((job) {
                          if (job['type'] == 'largo') {
                            final int jobId = FormatService.parseInt(job['id']);
                            final bool esCompletado =
                                (job['estado']?.toString().toLowerCase() == 'completado');
                            return JobCardLargo(
                              title: job['title'] ?? '',
                              frecuenciaPago: job['frecuenciaPago'] ?? '',
                              vacantesDisponibles: job['vacantesDisponibles'] ?? '',
                              vacantesDisponiblesInt: job['vacantesInt'] as int? ?? 0,
                              tipoObra: job['tipoObra'] ?? '',
                              fechaInicio: job['fechaInicio'] ?? '',
                              fechaFinal: job['fechaFinal'] ?? '',
                              latitud: job['latitud'] as double?,
                              longitud: job['longitud'] as double?,
                              direccion: job['direccion'] as String?,
                              estado: job['estado'] ?? 'activo',
                              onVerTrabajadores: () {
                                if (jobId <= 0) {
                                  CustomNotification.showError(
                                    context,
                                    'No se pudo obtener el identificador del trabajo.',
                                  );
                                  return;
                                }
                                _mostrarTrabajadoresAsignados(
                                  context,
                                  tipoTrabajo: 'largo',
                                  idTrabajo: jobId,
                                );
                              },
                              onTerminar: esCompletado || jobId <= 0
                                  ? null
                                  : () => _mostrarFlujoTerminar(
                                        context,
                                        tipoTrabajo: 'largo',
                                        idTrabajo: jobId,
                                      ),
                            );
                          } else {
                            final int jobId = FormatService.parseInt(job['id']);
                            final bool esCompletado =
                                (job['estado']?.toString().toLowerCase() == 'completado');
                            return JobCardCorto(
                              title: job['title'] ?? '',
                              rangoPrecio: job['rangoPrecio'] ?? '',
                              especialidad: job['especialidad'] ?? '',
                              disponibilidad: job['disponibilidad'] ?? '',
                              latitud: job['latitud'] as double?,
                              longitud: job['longitud'] as double?,
                              vacantesDisponibles: job['vacantesDisponibles'] ?? '',
                              vacantesDisponiblesInt: job['vacantesInt'] as int? ?? 0,
                              fechaCreacion: job['fechaCreacion'] as String?,
                              estado: job['estado'] ?? 'activo',
                              onVerTrabajadores: () {
                                if (jobId <= 0) {
                                  CustomNotification.showError(
                                    context,
                                    'No se pudo obtener el identificador del trabajo.',
                                  );
                                  return;
                                }
                                _mostrarTrabajadoresAsignados(
                                  context,
                                  tipoTrabajo: 'corto',
                                  idTrabajo: jobId,
                                );
                              },
                              onTerminar: esCompletado || jobId <= 0
                                  ? null
                                  : () => _mostrarFlujoTerminar(
                                        context,
                                        tipoTrabajo: 'corto',
                                        idTrabajo: jobId,
                                      ),
                            );
                          }
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Línea con sombra
class DividerWithShadow extends StatelessWidget {
  const DividerWithShadow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      height: 1,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: -2,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
