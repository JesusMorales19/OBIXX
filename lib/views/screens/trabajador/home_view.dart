import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/main_banner.dart';
import '../../widgets/trabajador/jobs_employee/job_category.dart';
import '../../widgets/trabajador/home_view/worker_card.dart';
import '../../widgets/custom_notification.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../../services/api_wrapper.dart';
import '../../../models/trabajo_largo_model.dart';
import '../../../models/trabajo_corto_model.dart';

class HomeViewEmployee extends StatefulWidget {
  const HomeViewEmployee({super.key});

  @override
  State<HomeViewEmployee> createState() => _HomeViewEmployeeState();
}

class _HomeViewEmployeeState extends State<HomeViewEmployee> with WidgetsBindingObserver {
  List<TrabajoLargoModel> _trabajosLargo = [];
  List<TrabajoCortoModel> _trabajosCorto = [];
  bool _isLoading = true;
  bool _tieneSolicitudPendiente = false;
  int _numeroSolicitudesActivas = 0;
  Set<String> _trabajosAplicados = {}; // Set de claves "tipoTrabajo-idTrabajo"
  String? _emailTrabajador;
  String? _claveAplicando;
  late VoidCallback _userListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userListener = () {
      final user = StorageService.userNotifier.value;
      final bool pendiente = user?['solicitudPendiente'] == true;
      if (pendiente != _tieneSolicitudPendiente && mounted) {
        setState(() {
          _tieneSolicitudPendiente = pendiente;
          if (!pendiente) {
            _claveAplicando = null;
          }
        });
      }
    };
    StorageService.userNotifier.addListener(_userListener);
    _cargarTrabajosCercanos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StorageService.userNotifier.removeListener(_userListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refrescar cuando la app vuelve al foreground
      _cargarTrabajosCercanos();
    }
  }


  /// Cargar trabajos cercanos desde la API
  Future<void> _cargarTrabajosCercanos() async {
    setState(() => _isLoading = true);

    final user = await StorageService.getUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final emailTrabajador = user['email']?.toString();
    if (emailTrabajador == null || emailTrabajador.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _emailTrabajador = emailTrabajador;

    final results = await ApiWrapper.safeCallMultiple<Map<String, dynamic>>(
      calls: [
        () => ApiService.buscarTrabajosCercanos(emailTrabajador, radio: 500),
        () => ApiService.buscarTrabajosCortoCercanos(emailTrabajador, radio: 500),
        () => ApiService.obtenerSolicitudPendienteTrabajador(emailTrabajador),
        () => ApiService.obtenerNumeroSolicitudesActivas(emailTrabajador),
        () => ApiService.obtenerSolicitudesActivasTrabajador(emailTrabajador),
      ],
      errorMessage: 'Error al cargar trabajos cercanos',
      showError: false,
    );

    final resultadoLargo = results[0];
    final resultadoCorto = results[1];
    final solicitudResponse = results[2];
    final numeroSolicitudesResult = results[3];
    final solicitudesActivasResult = results[4];

    final solicitudData = solicitudResponse?['data'];
    final bool tieneSolicitud = solicitudData != null;
    final numeroSolicitudes = FormatService.parseInt(numeroSolicitudesResult?['totalSolicitudes']);
    
    // Obtener lista de trabajos a los que ya aplicó
    final trabajosAplicadosList = solicitudesActivasResult?['trabajosAplicados'] as List<dynamic>? ?? [];
    final trabajosAplicadosSet = trabajosAplicadosList
        .map((t) => '${t['tipoTrabajo']}-${t['idTrabajo']}')
        .toSet();

    setState(() {
      if (resultadoLargo != null && resultadoLargo['success'] == true) {
        final trabajos = resultadoLargo['trabajos'] as List<dynamic>;
        _trabajosLargo = trabajos.map((t) => TrabajoLargoModel.fromJson(t)).toList();
      }

      if (resultadoCorto != null && resultadoCorto['success'] == true) {
        final trabajosCorto = resultadoCorto['trabajos'] as List<dynamic>;
        _trabajosCorto = trabajosCorto.map((t) => TrabajoCortoModel.fromJson(t)).toList();
      }

      _tieneSolicitudPendiente = tieneSolicitud;
      _numeroSolicitudesActivas = numeroSolicitudes;
      _trabajosAplicados = trabajosAplicadosSet;
      if (!tieneSolicitud) {
        _claveAplicando = null;
      }

      _isLoading = false;
    });

    if (tieneSolicitud) {
      await StorageService.mergeUser({'solicitudPendiente': true});
    } else {
      await StorageService.mergeUser({'solicitudPendiente': false});
    }
  }

  Future<void> _aplicarTrabajo({
    required String tipoTrabajo,
    required int idTrabajo,
  }) async {
    if (_emailTrabajador == null) {
      return;
    }

    // Verificar si ya aplicó a este trabajo específico
    final claveTrabajo = '$tipoTrabajo-$idTrabajo';
    if (_trabajosAplicados.contains(claveTrabajo)) {
      CustomNotification.showError(
        context,
        'Ya has aplicado a este trabajo. Espera la respuesta del contratista.',
      );
      return;
    }

    // Validar número de solicitudes activas
    if (_numeroSolicitudesActivas >= 3) {
      CustomNotification.showError(
        context,
        'Ya has alcanzado el límite de 3 solicitudes activas. Espera a que un contratista responda.',
      );
      return;
    }

    // Mostrar alertas según el número de solicitudes
    if (_numeroSolicitudesActivas == 2) {
      CustomNotification.showInfo(
        context,
        'Solo puedes solicitar ya 2 trabajos y solicita otro',
      );
    } else if (_numeroSolicitudesActivas == 1) {
      CustomNotification.showInfo(
        context,
        'Ya solo puedes solicitar 1 trabajo más',
      );
    }

    final clave = '$tipoTrabajo-$idTrabajo';

    setState(() {
      _claveAplicando = clave;
    });

    final response = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
      call: () => ApiService.aplicarASolicitud(
        emailTrabajador: _emailTrabajador!,
        tipoTrabajo: tipoTrabajo,
        idTrabajo: idTrabajo,
      ),
      errorMessage: 'Error al enviar solicitud',
    );

    if (!mounted) return;

    if (response['success'] == true) {
      // Actualizar número de solicitudes y agregar trabajo a la lista de aplicados
      final nuevoNumero = _numeroSolicitudesActivas + 1;
      final claveTrabajo = '$tipoTrabajo-$idTrabajo';
      await StorageService.mergeUser({'solicitudPendiente': nuevoNumero > 0});
      if (!mounted) return;
      setState(() {
        _numeroSolicitudesActivas = nuevoNumero;
        _tieneSolicitudPendiente = nuevoNumero > 0;
        _trabajosAplicados.add(claveTrabajo);
        _claveAplicando = null;
      });
      CustomNotification.showSuccess(
        context,
        'Solicitud enviada. Espera la respuesta del contratista.',
      );
      // Refrescar la lista de trabajos
      await _cargarTrabajosCercanos();
    } else {
      setState(() {
        _claveAplicando = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(
        role: 'trabajador',
        currentIndex: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(tipoUsuario: 'trabajador'),
            const SizedBox(height: 15),
            const MainBanner(),
            const SizedBox(height: 25),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _trabajosLargo.isEmpty && _trabajosCorto.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay trabajos cercanos disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 0, bottom: 20),
                                child: Text(
                                  'Trabajos disponibles',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              
                              // Trabajos Rápidos (Corto Plazo) - Solo datos estáticos por ahora
                              JobCategory(
                                title: 'Trabajos Rápidos',
                                tipoUsuario: 'trabajador',
                                jobs: _trabajosCorto.isNotEmpty
                                    ? _trabajosCorto.take(1).map((trabajo) {
                                        final contratistaNombre =
                                            [trabajo.nombreContratista, trabajo.apellidoContratista]
                                                .where((element) => element != null && element!.isNotEmpty)
                                                .join(' ');
                                        final idTrabajoCorto = trabajo.idTrabajoCorto;
                                        final claveTrabajo = 'corto-$idTrabajoCorto';
                                        final yaAplico = _trabajosAplicados.contains(claveTrabajo);
                                        final puedeAplicar = idTrabajoCorto != null &&
                                            !yaAplico &&
                                            _numeroSolicitudesActivas < 3 &&
                                            _claveAplicando == null &&
                                            trabajo.estado == 'activo' &&
                                            (trabajo.vacantesDisponibles ?? 0) > 0;
                                        return WorkerCard(
                                          title: trabajo.titulo,
                                          status: trabajo.estado == 'activo' ? 'Disponible' : 'No disponible',
                                          statusColor: trabajo.estado == 'activo' ? Colors.green : Colors.grey,
                                          ubication: trabajo.direccion ?? 'Sin dirección',
                                          payout: trabajo.rangoPago,
                                          moneda: trabajo.moneda,
                                          payoutLabel: 'Rango de pago',
                                          isLongTerm: false,
                                          vacancies: trabajo.vacantesDisponibles,
                                          contratista: contratistaNombre.isEmpty ? null : contratistaNombre,
                                          descripcion: trabajo.descripcion,
                                          fechaInicio: null,
                                          fechaFinal: null,
                                          imagenesBase64: trabajo.imagenesBase64,
                                          disponibilidad: trabajo.disponibilidad,
                                          especialidad: trabajo.especialidad,
                                          latitud: trabajo.latitud,
                                          longitud: trabajo.longitud,
                                          showApplyButton: idTrabajoCorto != null,
                                          canApply: puedeAplicar,
                                          isApplying: _claveAplicando == 'corto-$idTrabajoCorto',
                                          onApply: idTrabajoCorto == null
                                              ? null
                                              : () => _aplicarTrabajo(
                                                    tipoTrabajo: 'corto',
                                                    idTrabajo: idTrabajoCorto,
                                                  ),
                                        );
                                      }).toList()
                                    : const [
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Text(
                                            'No hay trabajos rápidos disponibles',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                              ),
                              
                              const SizedBox(height: 25),
                              
                              // Trabajos de Largo Plazo - Solo mostrar el primero
                              if (_trabajosLargo.isNotEmpty)
                                JobCategory(
                                  title: 'Trabajos Largo Plazo',
                                  tipoUsuario: 'trabajador',
                                  jobs: _trabajosLargo.take(1).map((trabajo) {
                                    final contratistaNombre =
                                        [trabajo.nombreContratista, trabajo.apellidoContratista]
                                            .where((element) => element != null && element!.isNotEmpty)
                                            .join(' ');

                                    final idTrabajoLargo = trabajo.idTrabajoLargo;
                                    final claveTrabajo = 'largo-$idTrabajoLargo';
                                    final yaAplico = _trabajosAplicados.contains(claveTrabajo);
                                    final puedeAplicar = idTrabajoLargo != null &&
                                        !yaAplico &&
                                        _numeroSolicitudesActivas < 3 &&
                                        _claveAplicando == null &&
                                        trabajo.estado == 'activo' &&
                                        (trabajo.vacantesDisponibles ?? 0) > 0;
                                    return WorkerCard(
                                      title: trabajo.titulo,
                                      status: trabajo.estado == 'activo' ? 'Disponible' : 'No disponible',
                                      statusColor: trabajo.estado == 'activo' ? Colors.green : Colors.grey,
                                      ubication: trabajo.direccion ?? 'Sin dirección',
                                      payout: trabajo.frecuencia ?? 'No especificado',
                                      payoutLabel: 'Frecuencia de trabajo',
                                      isLongTerm: true,
                                      vacancies: trabajo.vacantesDisponibles,
                                      contratista: contratistaNombre.isEmpty ? null : contratistaNombre,
                                      tipoObra: trabajo.tipoObra,
                                      fechaInicio: FormatService.formatDateFromIsoString(trabajo.fechaInicio),
                                      fechaFinal: FormatService.formatDateFromIsoString(trabajo.fechaFin),
                                      descripcion: trabajo.descripcion,
                                      latitud: trabajo.latitud,
                                      longitud: trabajo.longitud,
                                      showApplyButton: idTrabajoLargo != null,
                                      canApply: puedeAplicar,
                                      isApplying: _claveAplicando == 'largo-$idTrabajoLargo',
                                      onApply: idTrabajoLargo == null
                                          ? null
                                          : () => _aplicarTrabajo(
                                                tipoTrabajo: 'largo',
                                                idTrabajo: idTrabajoLargo,
                                              ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
