import 'package:flutter/material.dart';
import '../../widgets/trabajador/home_view/worker_card.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/main_banner.dart';
import '../../widgets/trabajador/home_view/search_bar.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../../services/api_wrapper.dart';
import '../../widgets/custom_notification.dart';

class VerMasScreen extends StatefulWidget {
  final String tipoUsuario; // 'trabajador' o 'contratista'
  final String categoria; // "Trabajos de corto plazo" o "Trabajos de largo plazo"

  const VerMasScreen({
    super.key,
    required this.tipoUsuario,
    required this.categoria,
  });

  @override
  State<VerMasScreen> createState() => _VerMasScreenState();
}

class _VerMasScreenState extends State<VerMasScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _trabajos = [];
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
    _searchController.addListener(_filterJobs);
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
    if (widget.categoria == 'Trabajos Largo Plazo') {
      _cargarTrabajosLargoPlazo();
    } else if (widget.categoria == 'Trabajos Rápidos') {
      _cargarTrabajosCortoPlazo();
    } else {
      setState(() => _isLoading = false);
    }
  }


  /// Cargar trabajos de largo plazo desde la API
  Future<void> _cargarTrabajosLargoPlazo() async {
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

    final results = await ApiWrapper.safeCallMultiple<Map<String, dynamic>>(
      calls: [
        () => ApiService.buscarTrabajosCercanos(emailTrabajador, radio: 500),
        () => ApiService.obtenerSolicitudPendienteTrabajador(emailTrabajador),
        () => ApiService.obtenerNumeroSolicitudesActivas(emailTrabajador),
        () => ApiService.obtenerSolicitudesActivasTrabajador(emailTrabajador),
      ],
      errorMessage: 'Error al cargar trabajos de largo plazo',
      showError: false,
    );

    final resultado = results[0];
    final solicitudResponse = results[1];
    final numeroSolicitudesResult = results[2];
    final solicitudesActivasResult = results[3];

    if (resultado != null && resultado['success'] == true) {
      final trabajos = resultado['trabajos'] as List<dynamic>;
      final tieneSolicitud = solicitudResponse?['data'] != null;
      final numeroSolicitudes = FormatService.parseInt(numeroSolicitudesResult?['totalSolicitudes']);
      
      // Obtener lista de trabajos a los que ya aplicó
      final trabajosAplicadosList = solicitudesActivasResult?['trabajosAplicados'] as List<dynamic>? ?? [];
      final trabajosAplicadosSet = trabajosAplicadosList
          .map((t) => '${t['tipoTrabajo']}-${t['idTrabajo']}')
          .toSet();

      setState(() {
        _emailTrabajador = emailTrabajador;
        _tieneSolicitudPendiente = tieneSolicitud;
        _numeroSolicitudesActivas = numeroSolicitudes;
        if (!tieneSolicitud) {
          _claveAplicando = null;
        }
        _trabajos = trabajos.map((t) {
          final nombreContratista = (
            [t['nombre_contratista'], t['apellido_contratista']]
                .whereType<String>()
                .where((parte) => parte.trim().isNotEmpty)
                .join(' ')
          ).trim();

          return {
            'id': t['id_trabajo_largo'] ?? t['idTrabajoLargo'],
            'estado': t['estado'] ?? 'activo',
            'title': t['titulo'] ?? '',
            'status': t['estado'] == 'activo' ? 'Disponible' : 'No disponible',
            'statusColor': t['estado'] == 'activo' ? Colors.green : Colors.grey,
            'ubication': t['direccion'] ?? 'Sin dirección',
            'payout': t['frecuencia'] ?? 'No especificado',
            'isLongTerm': true,
            'vacancies': FormatService.parseInt(t['vacantes_disponibles']),
            'contratista': nombreContratista.isEmpty ? t['email_contratista_full'] : nombreContratista,
            'tipoObra': t['tipo_obra'] ?? 'No especificado',
            'fechaInicio': t['fecha_inicio']?.toString() ?? '',
            'fechaFinal': t['fecha_fin']?.toString() ?? '',
            'descripcion': t['descripcion'] ?? '',
            'imagenes': const <String>[],
            'disponibilidad': null,
            'especialidad': t['tipo_obra'] ?? 'No especificado',
            'latitud': FormatService.parseDoubleNullable(t['latitud']),
            'longitud': FormatService.parseDoubleNullable(t['longitud']),
          };
        }).toList();

        _isLoading = false;
      });

      if (tieneSolicitud) {
        await StorageService.mergeUser({'solicitudPendiente': true});
      } else {
        await StorageService.mergeUser({'solicitudPendiente': false});
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarTrabajosCortoPlazo() async {
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

    final results = await ApiWrapper.safeCallMultiple<Map<String, dynamic>>(
      calls: [
        () => ApiService.buscarTrabajosCortoCercanos(emailTrabajador, radio: 500),
        () => ApiService.obtenerSolicitudPendienteTrabajador(emailTrabajador),
        () => ApiService.obtenerNumeroSolicitudesActivas(emailTrabajador),
        () => ApiService.obtenerSolicitudesActivasTrabajador(emailTrabajador),
      ],
      errorMessage: 'Error al cargar trabajos cortos',
      showError: false,
    );

    final resultado = results[0];
    final solicitudResponse = results[1];
    final numeroSolicitudesResult = results[2];
    final solicitudesActivasResult = results[3];

    if (resultado != null && resultado['success'] == true) {
      final trabajos = resultado['trabajos'] as List<dynamic>;
      final tieneSolicitud = solicitudResponse?['data'] != null;
      final numeroSolicitudes = FormatService.parseInt(numeroSolicitudesResult?['totalSolicitudes']);
      
      // Obtener lista de trabajos a los que ya aplicó
      final trabajosAplicadosList = solicitudesActivasResult?['trabajosAplicados'] as List<dynamic>? ?? [];
      final trabajosAplicadosSet = trabajosAplicadosList
          .map((t) => '${t['tipoTrabajo']}-${t['idTrabajo']}')
          .toSet();

      setState(() {
        _emailTrabajador = emailTrabajador;
        _tieneSolicitudPendiente = tieneSolicitud;
        _numeroSolicitudesActivas = numeroSolicitudes;
        _trabajosAplicados = trabajosAplicadosSet;
        if (!tieneSolicitud) {
          _claveAplicando = null;
        }

        _trabajos = trabajos.map((t) {
          final imagenes = <String>[];
          if (t['imagenes'] is List) {
            for (final img in t['imagenes']) {
              if (img is Map && img['imagen_base64'] != null) {
                imagenes.add(img['imagen_base64']);
              }
            }
          }

          final nombreContratista = (
            [t['nombre_contratista'], t['apellido_contratista']]
                .whereType<String>()
                .where((parte) => parte.trim().isNotEmpty)
                .join(' ')
          ).trim();

          return {
            'id': t['id_trabajo_corto'] ?? t['idTrabajoCorto'],
            'estado': t['estado'] ?? 'activo',
            'title': t['titulo'] ?? '',
            'status': t['estado'] == 'activo' ? 'Disponible' : 'No disponible',
            'statusColor': t['estado'] == 'activo' ? Colors.green : Colors.grey,
            'ubication': t['direccion'] ?? 'Sin dirección',
            'payout': t['rango_pago'] ?? 'No especificado',
            'moneda': t['moneda'] ?? 'MXN',
            'isLongTerm': false,
            'vacancies': FormatService.parseInt(t['vacantes_disponibles']),
            'contratista': nombreContratista.isEmpty ? t['email_contratista'] : nombreContratista,
            'tipoObra': t['especialidad'] ?? 'No especificado',
            'fechaInicio': null,
            'fechaFinal': null,
            'descripcion': t['descripcion'] ?? '',
            'imagenes': imagenes,
            'disponibilidad': t['disponibilidad'] ?? 'No especificada',
            'especialidad': t['especialidad'] ?? 'No especificado',
            'latitud': FormatService.parseDoubleNullable(t['latitud']),
            'longitud': FormatService.parseDoubleNullable(t['longitud']),
          };
        }).toList();

        _isLoading = false;
      });

      if (tieneSolicitud) {
        await StorageService.mergeUser({'solicitudPendiente': true});
      } else {
        await StorageService.mergeUser({'solicitudPendiente': false});
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    StorageService.userNotifier.removeListener(_userListener);
    super.dispose();
  }
  
  List<Map<String, dynamic>> _getAllJobs() {
    if (widget.categoria == "Trabajos Rápidos") {
      return _trabajos;
    } else if (widget.categoria == "Trabajos Largo Plazo") {
      // 🔸 Usa los trabajos cargados de la API
      return _trabajos;
    } else {
      return [];
    }
  }

  Future<void> _aplicarTrabajo({
    required String tipoTrabajo,
    required int idTrabajo,
  }) async {
    if (idTrabajo <= 0) {
      return;
    }

    final email = _emailTrabajador ??
        (await StorageService.getUser())?['email']?.toString();

    if (email == null || email.isEmpty) {
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
        emailTrabajador: email,
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
    } else {
      setState(() {
        _claveAplicando = null;
      });
    }
  }

  void _filterJobs() {
    setState(() {});
  }

  List<Map<String, dynamic>> _getFilteredJobs() {
    final allJobs = _getAllJobs();
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    if (searchQuery.isEmpty) {
      return allJobs;
    }
    
    return allJobs.where((job) {
      final title = job['title']?.toString().toLowerCase() ?? '';
      final especialidad = job['especialidad']?.toString().toLowerCase() ?? '';
      
      // Buscar en el título o en la especialidad
      return title.contains(searchQuery) || especialidad.contains(searchQuery);
    }).toList();
  }

  List<Widget> _getTrabajos() {
    final filteredJobs = _getFilteredJobs();
    
    if (filteredJobs.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No se encontraron trabajos',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      ];
    }
    
    return filteredJobs.map((trabajo) {
      final bool esLargo = trabajo['isLongTerm'] ?? false;
      final String label = esLargo ? 'Frecuencia de trabajo' : 'Rango de precio';
      final String payout = trabajo['payout'] ?? 'No especificado';
      final List<String> imagenes = (trabajo['imagenes'] as List?)?.map((e) => e.toString()).toList() ?? const [];
      final String disponibilidad = trabajo['disponibilidad']?.toString() ?? 'No especificada';
      final String especialidad = trabajo['especialidad']?.toString() ?? 'No especificado';
      final String contratistaNombre = trabajo['contratista']?.toString() ?? 'Sin contratista';
      final dynamic idRaw = trabajo['id'];
      final int? idTrabajo = FormatService.parseInt(idRaw) != 0 ? FormatService.parseInt(idRaw) : null;
      final String estado = (trabajo['estado'] ?? 'activo').toString();
      final int vacantes = FormatService.parseInt(trabajo['vacancies']);
      final bool tieneVacantes = vacantes > 0;
      final claveTrabajo = '${esLargo ? 'largo' : 'corto'}-$idTrabajo';
      final yaAplico = _trabajosAplicados.contains(claveTrabajo);
      final bool puedeAplicar = idTrabajo != null &&
          idTrabajo > 0 &&
          !yaAplico &&
          _numeroSolicitudesActivas < 3 &&
          _claveAplicando == null &&
          estado == 'activo' &&
          tieneVacantes;
 
      return WorkerCard(
        title: trabajo['title'] ?? '',
        status: trabajo['status'] ?? '',
        statusColor: trabajo['statusColor'] ?? Colors.green,
        ubication: trabajo['ubication'] ?? '',
        payout: payout,
        moneda: trabajo['moneda'],
        payoutLabel: label,
        isLongTerm: esLargo,
        vacancies: trabajo['vacancies'],
        contratista: contratistaNombre,
        tipoObra: trabajo['tipoObra'],
        fechaInicio: FormatService.formatDateFromIsoString(trabajo['fechaInicio']),
        fechaFinal: FormatService.formatDateFromIsoString(trabajo['fechaFinal']),
        descripcion: trabajo['descripcion'],
        imagenesBase64: imagenes,
        disponibilidad: disponibilidad,
        especialidad: especialidad,
        latitud: trabajo['latitud'] as double?,
        longitud: trabajo['longitud'] as double?,
        showApplyButton: idTrabajo != null,
        canApply: puedeAplicar,
        isApplying: idTrabajo != null &&
            _claveAplicando == '${esLargo ? 'largo' : 'corto'}-$idTrabajo',
        onApply: idTrabajo == null
            ? null
            : () => _aplicarTrabajo(
                  tipoTrabajo: esLargo ? 'largo' : 'corto',
                  idTrabajo: idTrabajo,
                ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(tipoUsuario: widget.tipoUsuario),
            const SizedBox(height: 10),
            const MainBanner(),
            const SizedBox(height: 15),
            CustomSearchBar(
              searchController: _searchController,
              onSearchChanged: (_) => _filterJobs(),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.categoria,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 30),
                            ..._getTrabajos(), // 👈 Aquí se muestran dinámicamente
                            const SizedBox(height: 25),
                          ],
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
