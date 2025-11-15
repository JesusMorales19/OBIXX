import 'package:flutter/material.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/main_banner.dart';
import '../../widgets/contratista/home_view/worker_card.dart';
import '../../widgets/contratista/home_view/filter_modal_see_more.dart';
import '../../widgets/custom_notification.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../../services/api_wrapper.dart';

class SeeMoreEmployees extends StatefulWidget {
  final String category;
  const SeeMoreEmployees({super.key, required this.category});

  @override
  State<SeeMoreEmployees> createState() => _SeeMoreEmployeesState();
}

class _SeeMoreEmployeesState extends State<SeeMoreEmployees> {
  double? minEdad;
  double? maxEdad;
  double? minExperiencia;
  double? minRating;

  final TextEditingController experienciaController = TextEditingController();
  final FocusNode experienciaFocusNode = FocusNode();

  // Lista de trabajadores de la API
  List<Map<String, dynamic>> allWorkers = [];
  bool _isLoading = true;
  String? _emailContratista;
  late VoidCallback _userListener;

  @override
  void initState() {
    super.initState();
    _userListener = () {
      final user = StorageService.userNotifier.value;
      final nuevoEmail = user?['email']?.toString();
      if (nuevoEmail != null && nuevoEmail != _emailContratista) {
        _cargarTrabajadoresDeCategoria();
      }
    };
    StorageService.userNotifier.addListener(_userListener);
    _cargarTrabajadoresDeCategoria();
  }

  /// Carga TODOS los trabajadores de esta categoría desde la API
  Future<void> _cargarTrabajadoresDeCategoria() async {
    setState(() => _isLoading = true);

    // Obtener email del usuario logueado
    final user = await StorageService.getUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final email = user['email'];

    // Buscar todos los trabajadores de esta categoría
    final resultado = await ApiWrapper.safeCall<Map<String, dynamic>>(
      call: () => ApiService.buscarTrabajadoresPorCategoria(
        email,
        widget.category,
        radio: 500,
      ),
      errorMessage: 'Error al cargar trabajadores',
      showError: false,
    );

    if (resultado != null && resultado['success'] == true) {
      final data = resultado['data'];
      final trabajadores = data['trabajadores'] as List<dynamic>;

      // Convertir trabajadores de la API al formato de la UI
      setState(() {
        _emailContratista = email;
        allWorkers = trabajadores.map((t) {
          final asignadoPor = t['contratista_asignado'];
          final asignadoPorMi = t['asignado_a_mi'] == true;
          final disponible = t['disponible'] == true;
          final asignadoAOtro = asignadoPor != null && !asignadoPorMi;

          final String statusTexto;
          final Color statusColor;
          if (asignadoPorMi) {
            statusTexto = 'Asignado a ti';
            statusColor = Colors.blue;
          } else if (disponible) {
            statusTexto = 'Disponible';
            statusColor = Colors.green;
          } else {
            statusTexto = 'Ocupado';
            statusColor = Colors.red;
          }

          final int? edadCalculada = _calcularEdadFromString(t['fecha_nacimiento']);
          final double rating = FormatService.parseDoubleNullable(t['calificacion_promedio']) ?? 0.0;
          final int experiencia = FormatService.parseInt(t['experiencia']);
          final descripcionApi = t['descripcion']?.toString().trim();
          final descripcionFinal = (descripcionApi != null && descripcionApi.isNotEmpty)
              ? descripcionApi
              : 'Experiencia: $experiencia años';

          return {
            'name': '${t['nombre']} ${t['apellido']}',
            'edad': edadCalculada,
            'categoria': t['categoria'],
            'descripcion': descripcionFinal,
            'status': statusTexto,
            'statusColor': statusColor,
            'image': 'assets/images/construccion.png',
            'foto_perfil': t['foto_perfil'], // Foto real del trabajador
            'rating': rating,
            'experiencia': experiencia,
            'email': t['email'],
            'telefono': t['telefono'],
            'distancia_km': FormatService.parseDoubleNullable(t['distancia_km']) ?? 0.0,
            'disponible': disponible,
            'isAssignedToCurrent': asignadoPorMi,
            'isAssignedToOther': asignadoAOtro,
            'assignedJobType': t['tipo_trabajo_asignado'],
            'assignedJobId': t['id_trabajo_asignado'],
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }


  int? _calcularEdadFromString(dynamic value) {
    if (value == null) return null;
    final texto = value.toString();
    if (texto.isEmpty) return null;
    final fecha = DateTime.tryParse(texto);
    if (fecha == null) return null;

    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }

  List<Map<String, dynamic>> get filteredWorkers => allWorkers.where((w) {
    if (w['categoria'] != widget.category) return false;

    final double? edad = FormatService.parseDoubleNullable(w['edad']);
    final double? experiencia = FormatService.parseDoubleNullable(w['experiencia']);
    final double? rating = FormatService.parseDoubleNullable(w['rating']);

    if (minEdad != null) {
      if (edad == null || edad < minEdad!) return false;
    }
    if (maxEdad != null) {
      if (edad == null || edad > maxEdad!) return false;
    }
    if (minExperiencia != null) {
      if (experiencia == null || experiencia < minExperiencia!) return false;
    }
    if (minRating != null) {
      if (rating == null || rating < minRating!) return false;
    }
    return true;
  }).toList();

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FilterModal(
        minEdad: minEdad,
        maxEdad: maxEdad,
        minExperiencia: minExperiencia,
        minRating: minRating,
        experienciaController: experienciaController,
        experienciaFocusNode: experienciaFocusNode,
        onApply: (edad, exp, rating) {
          setState(() {
            if (edad.start <= 18 && edad.end >= 60) {
              minEdad = null;
              maxEdad = null;
            } else {
              minEdad = edad.start;
              maxEdad = edad.end;
            }

            minExperiencia = exp > 0 ? exp : null;
            minRating = rating > 0
                ? double.parse(rating.toStringAsFixed(1))
                : null;

            if (minExperiencia != null && minExperiencia! > 0) {
              final value = minExperiencia!;
              experienciaController.text = value % 1 == 0
                  ? value.toStringAsFixed(0)
                  : value.toStringAsFixed(1);
            } else {
              experienciaController.clear();
            }
          });
        },
        onClear: () {
          setState(() {
            minEdad = null;
            maxEdad = null;
            minExperiencia = null;
            minRating = null;
            experienciaController.clear();
          });
        },
      ),
    );
  }

  Future<void> _onAssignmentChanged() async {
    await _cargarTrabajadoresDeCategoria();
  }

  Future<void> _cancelarAsignacion(String emailTrabajador) async {
    if (_emailContratista == null) {
      CustomNotification.showError(context, 'No se encontró la sesión del contratista');
      return;
    }

    try {
      final respuesta = await ApiService.cancelarAsignacion(
        emailContratista: _emailContratista!,
        emailTrabajador: emailTrabajador,
      );

      if (respuesta['success'] == true) {
        if (mounted) {
          CustomNotification.showSuccess(context, 'Asignación cancelada correctamente');
        }
        await _onAssignmentChanged();
      } else {
        if (mounted) {
          CustomNotification.showError(
            context,
            respuesta['error']?.toString() ?? 'No se pudo cancelar la asignación',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error al cancelar asignación: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    StorageService.userNotifier.removeListener(_userListener);
    experienciaController.dispose();
    experienciaFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(tipoUsuario: 'contratista'),
            const SizedBox(height: 15),
            const MainBanner(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filtrar empleados", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black)),
                  IconButton(icon: const Icon(Icons.filter_list,color: Colors.blueAccent,size: 30), onPressed: _openFilterSheet),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.category, style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 22)),
                          const SizedBox(height: 20),
                          if (filteredWorkers.isEmpty)
                            const Text('No hay empleados cercanos en esta categoría.', style: TextStyle(color: Colors.grey)),
                          for (var worker in filteredWorkers)
                            WorkerCard(
                              name: worker['name'] ?? 'Sin nombre',
                              edad: (worker['edad'] is num)
                                  ? (worker['edad'] as num).round()
                                  : 0,
                              categoria: worker['categoria'] ?? widget.category,
                              descripcion: (worker['descripcion'] ?? '')
                                  .toString(),
                              status: worker['status'],
                              statusColor: worker['statusColor'],
                              image: worker['image'],
                              fotoPerfil: worker['foto_perfil'],
                              rating: FormatService.parseDouble(worker['rating']),
                              experiencia: FormatService.parseInt(worker['experiencia']),
                              email: worker['email'] ?? '',
                              telefono: worker['telefono'] ?? '',
                              disponible: worker['disponible'] ?? true,
                              isAssignedToCurrent: worker['isAssignedToCurrent'] ?? false,
                              isAssignedToOther: worker['isAssignedToOther'] ?? false,
                              assignedJobType: worker['assignedJobType'],
                              assignedJobId: worker['assignedJobId'],
                              onAssignmentChanged: () => _onAssignmentChanged(),
                              onCancelAssignment: (worker['isAssignedToCurrent'] == true)
                                  ? () => _cancelarAsignacion(worker['email'] ?? '')
                                  : null,
                            ),
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