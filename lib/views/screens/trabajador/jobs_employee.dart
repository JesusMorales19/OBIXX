import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/main_banner.dart';
import '../../widgets/trabajador/jobs_employee/worker_card_jobs.dart';

import 'package:intl/intl.dart';

import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../../services/api_wrapper.dart';

class JobsViewEmployee extends StatefulWidget {
  const JobsViewEmployee({super.key});

  @override
  State<JobsViewEmployee> createState() => _JobsViewEmployeeState();
}

class _JobsViewEmployeeState extends State<JobsViewEmployee> {
  bool _isLoading = true;
  Map<String, dynamic>? _trabajoActual;
  Map<String, dynamic>? _perfilTrabajador;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = await StorageService.getUser();
    final emailTrabajador = user?['email']?.toString();

    if (emailTrabajador == null) {
      setState(() {
        _isLoading = false;
        _error = 'No se encontró una sesión activa de trabajador.';
      });
      return;
    }

    final resultados = await ApiWrapper.safeCallMultiple<Map<String, dynamic>>(
      calls: [
        () => ApiService.obtenerTrabajoActualTrabajador(emailTrabajador),
        () => ApiService.obtenerPerfilTrabajador(emailTrabajador),
      ],
      errorMessage: 'Error al cargar datos del trabajador',
      showError: false,
    );

    final asignacionResp = resultados[0];
    final perfilResp = resultados[1];

    Map<String, dynamic>? trabajoActual;
    if (asignacionResp != null && asignacionResp['success'] == true) {
      trabajoActual = asignacionResp['data'] as Map<String, dynamic>?;
    } else if (asignacionResp != null) {
      _error = asignacionResp['error']?.toString();
    } else {
      _error = 'Error al cargar datos del trabajo actual';
    }

    Map<String, dynamic>? perfil;
    if (perfilResp != null && perfilResp['success'] == true) {
      perfil = perfilResp['data'] as Map<String, dynamic>?;
    }

    setState(() {
      _trabajoActual = trabajoActual;
      _perfilTrabajador = perfil;
      _isLoading = false;
    });
  }

  String _nombreCompletoTrabajador() {
    final nombre = (_perfilTrabajador?['nombre'] ?? '').toString().trim();
    final apellido = (_perfilTrabajador?['apellido'] ?? '').toString().trim();
    final completo = [nombre, apellido].where((p) => p.isNotEmpty).join(' ');
    return completo.isNotEmpty ? completo : 'Sin nombre';
  }

  String? _fotoTrabajador() {
    final foto = _perfilTrabajador?['foto_perfil'];
    return foto is String && foto.isNotEmpty ? foto : null;
  }

  double? _ratingTrabajador() {
    final rating = _perfilTrabajador?['calificacion_promedio'];
    if (rating == null) return null;
    return FormatService.parseDoubleNullable(rating);
  }

  Future<void> _finalizarContrato() async {
    final trabajo = _trabajoActual;
    final perfil = _perfilTrabajador;

    if (trabajo == null || perfil == null) return;

    final contratista = (trabajo['trabajo']?['contratista'] ?? trabajo['contratista']) as Map<String, dynamic>? ?? {};
    String? emailContratista = contratista['email']?.toString();
    if (emailContratista == null || emailContratista.isEmpty) {
      final fallback = (_trabajoActual!['contratista'] ?? {}) as Map<String, dynamic>;
      emailContratista = fallback['email']?.toString();
    }
    final emailTrabajador = perfil['email']?.toString() ?? perfil['correo']?.toString();

    if (emailContratista == null || emailTrabajador == null) {
      if (!mounted) return;
      CustomNotification.showError(
        context,
        'No se pudo identificar al contratista para finalizar el contrato.',
      );
      return;
    }

    try {
      final respuesta = await ApiService.cancelarAsignacion(
        emailContratista: emailContratista,
        emailTrabajador: emailTrabajador,
        iniciadoPorTrabajador: true,
        skipDefaultNotification: true,
      );

      if (!mounted) return;

      if (respuesta['success'] == true) {
        CustomNotification.showSuccess(
          context,
          'Has finalizado el contrato exitosamente.',
        );
        final user = await StorageService.getUser();
        if (user != null) {
          final actualizado = Map<String, dynamic>.from(user);
          actualizado['disponible'] = true;
          await StorageService.saveUser(actualizado);
        }
        await _cargarDatos();
      } else {
        final mensaje = respuesta['error']?.toString() ?? 'No se pudo finalizar el contrato.';
        CustomNotification.showError(
          context,
          mensaje,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomNotification.showError(
        context,
        'Ocurrió un error al terminar el contrato: $e',
      );
    }
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_trabajoActual == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No tienes un trabajo asignado actualmente.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    final tipoTrabajo = _trabajoActual!['tipoTrabajo']?.toString();
    final trabajo = (_trabajoActual!['trabajo'] ?? {}) as Map<String, dynamic>;
    final contratista =
        (trabajo['contratista'] ?? _trabajoActual!['contratista'] ?? {}) as Map<String, dynamic>;
    String nombreContratista = (contratista['nombreCompleto'] ?? '').toString().trim();
    if (nombreContratista.isEmpty) {
      final partes = [
        contratista['nombre']?.toString().trim() ?? '',
        contratista['apellido']?.toString().trim() ?? '',
      ].where((parte) => parte.isNotEmpty).toList();
      nombreContratista = partes.join(' ');
    }
    if (nombreContratista.isEmpty) {
      nombreContratista = contratista['email']?.toString() ?? 'Sin contratista';
    }

    final titulo = trabajo['titulo']?.toString() ?? 'Trabajo asignado';
    final latitud = FormatService.parseDoubleNullable(trabajo['latitud']);
    final longitud = FormatService.parseDoubleNullable(trabajo['longitud']);

    String? rangoPrecio;
    String? especialidad;
    String? disponibilidad;
    String? frecuenciaPago;
    String? tipoObra;
    String? fechaFinal;

    if (tipoTrabajo == 'corto') {
      rangoPrecio = trabajo['rangoPago']?.toString();
      especialidad = trabajo['especialidad']?.toString();
      disponibilidad = trabajo['disponibilidad']?.toString();
    } else {
      frecuenciaPago = trabajo['frecuencia']?.toString();
      tipoObra = trabajo['tipoObra']?.toString();
      fechaFinal = trabajo['fechaFin']?.toString();
      if (fechaFinal != null && fechaFinal.isNotEmpty) {
        try {
          fechaFinal = DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaFinal));
        } catch (_) {
          fechaFinal = fechaFinal?.split('T').first;
        }
      }
    }

    String? fotoTrabajadorBase64 = _fotoTrabajador();
    if (fotoTrabajadorBase64 != null && fotoTrabajadorBase64.contains(',')) {
      fotoTrabajadorBase64 = fotoTrabajadorBase64.split(',').last;
    }

    return WorkerCardJobs(
      esTrabajoLargo: tipoTrabajo == 'largo',
      tituloTrabajo: titulo,
      nombreContratista: nombreContratista ?? 'Sin contratista',
      rangoPrecio: rangoPrecio,
      especialidad: especialidad,
      disponibilidad: disponibilidad,
      frecuenciaPago: frecuenciaPago,
      tipoObra: tipoObra,
      fechaFinal: fechaFinal,
      latitud: latitud,
      longitud: longitud,
      direccion: trabajo['direccion']?.toString(),
      nombreTrabajador: _nombreCompletoTrabajador(),
      fotoTrabajadorBase64: fotoTrabajadorBase64,
      calificacionTrabajador: _ratingTrabajador(),
      onCancelarContrato: _finalizarContrato,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(
        role: 'trabajador',
        currentIndex: 1,
        ),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(tipoUsuario: 'trabajador'),
            const SizedBox(height: 15),
            const MainBanner(),
            const SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 0, bottom: 20),
                      child: Text(
                        'Trabajo Activo',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildContenido(),
                  ],
                )
              ))
          ],
        ),
      ),
    );
  }
}