import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ---------- IMPORTACIÓN DE TUS COMPONENTES ----------
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/main_banner.dart';
import '../../widgets/contratista/home_view/search_and_filter_bar.dart';
import '../../widgets/contratista/home_view/service_category.dart';
import '../../widgets/contratista/home_view/worker_card.dart';
import '../../widgets/contratista/location_picker_widget.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../widgets/common/loading_button.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/api_wrapper.dart';
import '../../../services/format_service.dart';
import '../../../models/trabajo_largo_model.dart';
import '../../../models/trabajo_corto_model.dart';

class HomeViewContractor extends StatefulWidget {
  const HomeViewContractor({super.key});

  @override
  State<HomeViewContractor> createState() => _HomeViewContractorState();
}

class _HomeViewContractorState extends State<HomeViewContractor> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todas';

  // Lista de trabajadores cercanos (de la API)
  List<Map<String, dynamic>> _allWorkers = [];
  bool _isLoadingWorkers = true;
  String? _userEmail;
  late VoidCallback _userListener;
  
  // Lista de trabajadores favoritos
  List<Map<String, dynamic>> _favoritosWorkers = [];
  bool _isLoadingFavoritos = false;

  Future<void> _onAssignmentChanged() async {
    await _cargarTrabajadoresCercanos();
    await _cargarFavoritos();
  }

  @override
  void initState() {
    super.initState();
    _userListener = () {
      final user = StorageService.userNotifier.value;
      final newEmail = user?['email']?.toString();
      if (newEmail != null && newEmail != _userEmail) {
        _cargarTrabajadoresCercanos();
        _cargarFavoritos();
      }
    };
    StorageService.userNotifier.addListener(_userListener);
    _searchController.addListener(_filterWorkers);
    _cargarTrabajadoresCercanos();
  }

  @override
  void dispose() {
    StorageService.userNotifier.removeListener(_userListener);
    _searchController.dispose();
    super.dispose();
  }

  /// Carga trabajadores cercanos desde la API
  Future<void> _cargarTrabajadoresCercanos() async {
    setState(() => _isLoadingWorkers = true);

    // Obtener email del usuario logueado
    final user = await StorageService.getUser();
    if (user == null) {
      setState(() => _isLoadingWorkers = false);
      return;
    }

    _userEmail = user['email'];

    // Buscar trabajadores cercanos (radio 500km)
    final resultado = await ApiWrapper.safeCall<Map<String, dynamic>>(
      call: () => ApiService.buscarTrabajadoresCercanos(_userEmail!, radio: 500),
      errorMessage: 'Error al cargar trabajadores cercanos',
      showError: false,
    );

    if (resultado != null && resultado['success'] == true) {
      final data = resultado['data'];
      final trabajadores = data['trabajadores'] as List<dynamic>;

      // Convertir trabajadores de la API al formato de la UI
      setState(() {
        _allWorkers = trabajadores.map((t) {
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

          return {
            'name': '${t['nombre']} ${t['apellido']}',
            'edad': 0, // No tenemos edad en la BD
            'categoria': t['categoria'],
            'title': t['categoria'],
            'descripcion': 'Experiencia: ${t['experiencia']} años',
            'status': statusTexto,
            'statusColor': statusColor,
            'image': 'assets/images/construccion.png', // Imagen por defecto
            'foto_perfil': t['foto_perfil'], // Foto real del trabajador
            'rating': FormatService.parseDouble(t['calificacion_promedio']),
            'experiencia': FormatService.parseInt(t['experiencia']),
            'email': t['email'],
            'telefono': t['telefono'],
            'distancia_km': FormatService.parseDouble(t['distancia_km']),
            'disponible': disponible,
            'isAssignedToCurrent': asignadoPorMi,
            'isAssignedToOther': asignadoAOtro,
            'assignedJobType': t['tipo_trabajo_asignado'],
            'assignedJobId': t['id_trabajo_asignado'],
          };
        }).toList();
        _isLoadingWorkers = false;
      });
    } else {
      setState(() => _isLoadingWorkers = false);
    }
  }


  void _filterWorkers() {
    setState(() {});
  }
  
  /// Carga los trabajadores favoritos desde la API
  Future<void> _cargarFavoritos() async {
    if (_userEmail == null) {
      return;
    }
    
    setState(() => _isLoadingFavoritos = true);
    
    final resultado = await ApiWrapper.safeCall<Map<String, dynamic>>(
      call: () => ApiService.listarFavoritos(_userEmail!),
      errorMessage: 'Error al cargar favoritos',
      showError: false,
    );
    
    if (resultado != null && resultado['success'] == true) {
      final favoritos = resultado['favoritos'] as List<dynamic>;
      
      setState(() {
        _favoritosWorkers = favoritos.map((t) {
          Map<String, dynamic>? existente;
          try {
            existente = _allWorkers.firstWhere(
              (worker) => worker['email'] == t['email'],
            );
          } catch (_) {
            existente = null;
          }

          if (existente != null) {
            return Map<String, dynamic>.from(existente);
          }

          final disponible = t['disponible'] == true;

          return {
            'name': '${t['nombre']} ${t['apellido']}',
            'categoria': t['categoria'],
            'title': t['categoria'],
            'descripcion': 'Experiencia: ${t['experiencia']} años',
            'status': disponible ? 'Disponible' : 'Ocupado',
            'statusColor': disponible ? Colors.green : Colors.red,
            'image': 'assets/images/construccion.png',
            'foto_perfil': t['foto_perfil'], // Foto real del trabajador
            'rating': FormatService.parseDouble(t['calificacion_promedio']),
            'experiencia': FormatService.parseInt(t['experiencia']),
            'email': t['email'],
            'telefono': t['telefono'],
            'edad': 0,
            'disponible': disponible,
            'isAssignedToCurrent': false,
            'isAssignedToOther': !disponible,
            'assignedJobType': null,
            'assignedJobId': null,
          };
        }).toList();
        _isLoadingFavoritos = false;
      });
    } else {
      setState(() => _isLoadingFavoritos = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredWorkers() {
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    // Si está en modo Favoritos, usar lista de favoritos
    List<Map<String, dynamic>> workersList = _selectedFilter == 'Favoritos' 
        ? _favoritosWorkers 
        : _allWorkers;
    
    return workersList.where((worker) {
      
      // Filtrar por nombre O por categoría
      if (searchQuery.isNotEmpty) {
        final name = worker['name']?.toString().toLowerCase() ?? '';
        final categoria = worker['categoria']?.toString().toLowerCase() ?? '';
        
        // Debe coincidir con el nombre O con la categoría
        if (!name.contains(searchQuery) && !categoria.contains(searchQuery)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupWorkersByCategory() {
    final filtered = _getFilteredWorkers();
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var worker in filtered) {
      final category = worker['title'] ?? 'Otros';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(worker);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // Solo agrupar si NO estamos en favoritos
    final groupedWorkers = _selectedFilter == 'Favoritos' 
        ? <String, List<Map<String, dynamic>>>{}
        : _groupWorkersByCategory();
    
    final filteredWorkers = _getFilteredWorkers();
    
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(
        role: 'contratista',
        currentIndex: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(tipoUsuario: 'contratista'),
            const SizedBox(height: 15),
            const MainBanner(),
            const SizedBox(height: 25),
            SearchAndFilterBar(
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              onFilterChanged: (value) {
                setState(() {
                  _selectedFilter = value;
                });
                // Si cambia a Favoritos, cargar favoritos
                if (value == 'Favoritos') {
                  _cargarFavoritos();
                }
              },
              onSearchChanged: (_) => _filterWorkers(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: (_isLoadingWorkers || (_selectedFilter == 'Favoritos' && _isLoadingFavoritos))
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedFilter == 'Favoritos'
                      // VISTA DE FAVORITOS - LISTA SIMPLE
                      ? filteredWorkers.isEmpty
                          ? const Center(
                              child: Text(
                                'No tienes trabajadores favoritos',
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
                                  const Text(
                                    'Mis Favoritos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Lista de todos los trabajadores favoritos
                                  ...filteredWorkers.map((worker) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: WorkerCard(
                                        name: worker['name'] ?? '',
                                        edad: worker['edad'] ?? 0,
                                        categoria: worker['categoria'] ?? '',
                                        descripcion: worker['descripcion'] ?? '',
                                        status: worker['status'] ?? '',
                                        statusColor: worker['statusColor'] ?? Colors.grey,
                                        image: worker['image'] ?? '',
                                        fotoPerfil: worker['foto_perfil'],
                                        rating: FormatService.parseDouble(worker['rating']),
                                        experiencia: worker['experiencia'] ?? 0,
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
                                    );
                                  }).toList(),
                                  const SizedBox(height: 70),
                                ],
                              ),
                            )
                      // VISTA NORMAL - AGRUPADO POR CATEGORÍAS
                      : groupedWorkers.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron trabajadores cercanos',
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
                                  const Text(
                                    'Servicios A Ofrecer',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...groupedWorkers.entries.map((entry) {
                                    return ServiceCategory(
                                      title: entry.key,
                                      workers: entry.value.map((worker) {
                                        return WorkerCard(
                                          name: worker['name'] ?? '',
                                          edad: worker['edad'] ?? 0,
                                          categoria: worker['categoria'] ?? '',
                                          descripcion: worker['descripcion'] ?? '',
                                          status: worker['status'] ?? '',
                                          statusColor: worker['statusColor'] ?? Colors.grey,
                                          image: worker['image'] ?? '',
                                          fotoPerfil: worker['foto_perfil'],
                                          rating: FormatService.parseDouble(worker['rating']),
                                          experiencia: worker['experiencia'] ?? 0,
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
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 70),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
      // ---------- BOTÓN FLOTANTE ----------
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFFE67E22),
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          // BOTÓN CORTO PLAZO
          SpeedDialChild(
            child: const Icon(Icons.work_outline, color: Colors.white, size: 28),
            backgroundColor: Colors.blue,
            label: 'Registro Trabajo Corto Plazo',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            labelBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RegistroCortoPlazoModal(),
              );
            },
          ),

          // BOTÓN LARGO PLAZO
          SpeedDialChild(
            child: const Icon(Icons.work, color: Colors.white, size: 28),
            backgroundColor: Colors.green,
            label: 'Registro Trabajo Largo Plazo',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            labelBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RegistroLargoPlazoModal(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarAsignacion(String emailTrabajador) async {
    if (_userEmail == null) return;

    final respuesta = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
      call: () => ApiService.cancelarAsignacion(
        emailContratista: _userEmail!,
        emailTrabajador: emailTrabajador,
        skipDefaultNotification: true,
      ),
      errorMessage: 'Error al cancelar asignación',
    );

    if (respuesta['success'] == true) {
      if (mounted) {
        CustomNotification.showSuccess(
          context,
          'Asignación cancelada correctamente',
        );
      }
      await _onAssignmentChanged();
    }
  }

  Future<void> _closeSession(BuildContext context) async {
    Navigator.pop(context);
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

// ---------------------- MODAL REGISTRO CORTO PLAZO ----------------------
class RegistroCortoPlazoModal extends StatefulWidget {
  const RegistroCortoPlazoModal({super.key});

  @override
  State<RegistroCortoPlazoModal> createState() =>
      _RegistroCortoPlazoModalState();
}

class _RegistroCortoPlazoModalState extends State<RegistroCortoPlazoModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _rangoPrecioController = TextEditingController();
  final TextEditingController _vacantesController = TextEditingController();
  String? disponibilidad;
  String? especialidad;
  String moneda = 'MXN';
  double? _latitud;
  double? _longitud;
  String? _direccion;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _imagenes = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _rangoPrecioController.dispose();
    _vacantesController.dispose();
    super.dispose();
  }

  Future<void> _agregarImagenDesdeGaleria() async {
    final seleccionadas = await _picker.pickMultiImage(imageQuality: 75, maxWidth: 1280, maxHeight: 1280);
    if (seleccionadas != null && seleccionadas.isNotEmpty) {
      setState(() => _imagenes.addAll(seleccionadas));
    }
  }

  Future<void> _agregarImagenDesdeCamara() async {
    final foto = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1280, maxHeight: 1280);
    if (foto != null) {
      setState(() => _imagenes.add(foto));
    }
  }

  Future<void> _registrarTrabajoCorto() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que tenga al menos dirección o coordenadas
    if ((_latitud == null || _longitud == null) && (_direccion == null || _direccion!.isEmpty)) {
      CustomNotification.showError(
        context,
        'Debes proporcionar la ubicación del trabajo (coordenadas o dirección).',
      );
      return;
    }

    if (_imagenes.isEmpty) {
      CustomNotification.showError(
        context,
        'Selecciona al menos una fotografía.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = await StorageService.getUser();
    if (user == null) {
      setState(() => _isSubmitting = false);
      CustomNotification.showError(
        context,
        'No se pudo obtener la sesión del usuario.',
      );
      return;
    }

    try {
      final imagenesBase64 = await Future.wait(_imagenes.map((img) async {
        final bytes = await File(img.path).readAsBytes();
        return base64Encode(bytes);
      }));

      final trabajo = TrabajoCortoModel(
        emailContratista: user['email'],
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        rangoPago: _rangoPrecioController.text.trim(),
        moneda: moneda,
        latitud: _latitud,
        longitud: _longitud,
        direccion: _direccion,
        disponibilidad: disponibilidad,
        especialidad: especialidad,
        vacantesDisponibles: int.parse(_vacantesController.text.trim()),
        imagenesBase64: imagenesBase64,
      );

      final resultado = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
        call: () => ApiService.registrarTrabajoCortoPlazo(trabajo),
        errorMessage: 'Error al registrar trabajo',
      );

      setState(() => _isSubmitting = false);

      if (resultado['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          CustomNotification.showSuccess(context, 'Trabajo de corto plazo registrado.');
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error inesperado: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Registrar Trabajo Corto Plazo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 25),
                CustomTextField(
                  controller: _tituloController,
                  label: 'Título del trabajo',
                  icon: Icons.title,
                  iconColor: Colors.blueAccent,
                  borderColor: Colors.blueAccent,
                ),
                CustomTextField(
                  controller: _descripcionController,
                  label: 'Descripción breve',
                  icon: Icons.description,
                  maxLines: 3,
                  iconColor: Colors.blueAccent,
                  borderColor: Colors.blueAccent,
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _rangoPrecioController,
                        label: 'Rango de precio (Ej: 500 - 800)',
                        icon: Icons.attach_money,
                        iconColor: Colors.blueAccent,
                        borderColor: Colors.blueAccent,
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
                          setState(() {
                            moneda = value ?? 'MXN';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                CustomTextField(
                  controller: _vacantesController,
                  label: 'Vacantes disponibles',
                  icon: Icons.group,
                  keyboardType: TextInputType.number,
                  iconColor: Colors.blueAccent,
                  borderColor: Colors.blueAccent,
                ),
                const SizedBox(height: 10),
                LocationPickerWidget(
                  onLocationSelected: (lat, lon, direccion) {
                    setState(() {
                      _latitud = lat;
                      _longitud = lon;
                      _direccion = direccion;
                    });
                  },
                  initialLat: _latitud,
                  initialLon: _longitud,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _agregarImagenDesdeCamara,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Tomar foto'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _agregarImagenDesdeGaleria,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_imagenes.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenes.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_imagenes[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 14,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imagenes.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomDropdown<String>(
                  label: 'Disponibilidad',
                  icon: Icons.access_time,
                  value: disponibilidad,
                  items: ['Inmediata', 'Dentro de 3 días', 'Una semana'],
                  onChanged: (v) => setState(() => disponibilidad = v),
                  iconColor: Colors.blueAccent,
                  borderColor: Colors.blueAccent,
                  validator: (value) => value == null ? 'Seleccione una opción' : null,
                ),
                CustomDropdown<String>(
                  label: 'Especialidad requerida',
                  icon: Icons.handyman,
                  value: especialidad,
                  items: ['Albañil', 'Electricista', 'Carpintero', 'Plomero', 'Pintor'],
                  onChanged: (v) => setState(() => especialidad = v),
                ),
                const SizedBox(height: 25),
                LoadingButton(
                  onPressed: _registrarTrabajoCorto,
                  label: 'Registrar Trabajo',
                  icon: Icons.check_circle_outline,
                  isLoading: _isSubmitting,
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  borderRadius: BorderRadius.circular(15),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  loadingText: 'Registrando...',
                  iconSize: 18,
                  loadingIndicatorSize: 18,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ---------------------- MODAL REGISTRO LARGO PLAZO ----------------------
class RegistroLargoPlazoModal extends StatefulWidget {
  const RegistroLargoPlazoModal({super.key});

  @override
  State<RegistroLargoPlazoModal> createState() =>
      _RegistroLargoPlazoModalState();
}

class _RegistroLargoPlazoModalState extends State<RegistroLargoPlazoModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _vacantesController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinalController = TextEditingController();
  
  String? frecuencia;
  String? tipoObra;
  
  double? _latitud;
  double? _longitud;
  String? _direccion;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _vacantesController.dispose();
    _fechaInicioController.dispose();
    _fechaFinalController.dispose();
    super.dispose();
  }

  Future<void> _registrarTrabajo() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que tenga al menos dirección o coordenadas
    if ((_latitud == null || _longitud == null) && (_direccion == null || _direccion!.isEmpty)) {
      CustomNotification.showError(
        context,
        'Debes proporcionar la ubicación del trabajo (coordenadas o dirección).',
      );
      return;
    }

    setState(() => _isLoading = true);

    // Obtener email del contratista logueado
    final user = await StorageService.getUser();
    if (user == null) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error: No se pudo obtener el usuario',
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final emailContratista = user['email'];

      final trabajo = TrabajoLargoModel(
        emailContratista: emailContratista,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        latitud: _latitud,
        longitud: _longitud,
        direccion: _direccion,
        fechaInicio: _fechaInicioController.text.trim(),
        fechaFin: _fechaFinalController.text.trim(),
        vacantesDisponibles: int.parse(_vacantesController.text.trim()),
        tipoObra: tipoObra,
        frecuencia: frecuencia,
      );

      // Registrar el trabajo
      final resultado = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
        call: () => ApiService.registrarTrabajoLargoPlazo(trabajo),
        errorMessage: 'Error al registrar trabajo',
      );

      setState(() => _isLoading = false);

      if (resultado['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          CustomNotification.showSuccess(
            context,
            'Trabajo registrado exitosamente',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Registrar Trabajo Largo Plazo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 25),
                CustomTextField(
                  controller: _tituloController,
                  label: 'Título del trabajo',
                  icon: Icons.title,
                  iconColor: Colors.green,
                  borderColor: Colors.green,
                ),
                CustomTextField(
                  controller: _descripcionController,
                  label: 'Descripción detallada',
                  icon: Icons.description,
                  maxLines: 1,
                  iconColor: Colors.green,
                  borderColor: Colors.green,
                ),
                
                // Widget de ubicación
                LocationPickerWidget(
                  onLocationSelected: (lat, lon, direccion) {
                    setState(() {
                      _latitud = lat;
                      _longitud = lon;
                      _direccion = direccion;
                    });
                  },
                  initialLat: _latitud,
                  initialLon: _longitud,
                ),
                const SizedBox(height: 15),
                
                CustomTextField(
                  controller: _vacantesController,
                  label: 'Número de vacantes',
                  icon: Icons.people,
                  hint: 'Ej: 3',
                  keyboardType: TextInputType.number,
                  iconColor: Colors.green,
                  borderColor: Colors.green,
                ),
                CustomDropdown<String>(
                  label: 'Frecuencia de trabajo',
                  icon: Icons.schedule,
                  value: frecuencia,
                  items: ['Semanal', 'Quincenal'],
                  onChanged: (v) => setState(() => frecuencia = v),
                  iconColor: Colors.green,
                  borderColor: Colors.green,
                  validator: (value) => value == null ? 'Seleccione una opción' : null,
                ),
                _buildDateField(Icons.date_range, 'Fecha de inicio', _fechaInicioController),
                _buildDateField(Icons.date_range, 'Fecha de finalización', _fechaFinalController),
                CustomDropdown<String>(
                  label: 'Tipo de obra',
                  icon: Icons.construction,
                  value: tipoObra,
                  items: ['Construcción', 'Remodelación', 'Mantenimiento', 'Reparación'],
                  onChanged: (v) => setState(() => tipoObra = v),
                  iconColor: Colors.green,
                  borderColor: Colors.green,
                  validator: (value) => value == null ? 'Seleccione una opción' : null,
                ),
                const SizedBox(height: 15),
                LoadingButton(
                  onPressed: _registrarTrabajo,
                  label: 'Registrar Trabajo',
                  icon: Icons.check_circle_outline,
                  isLoading: _isLoading,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  borderRadius: BorderRadius.circular(15),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  loadingText: 'Registrando...',
                  iconSize: 18,
                  loadingIndicatorSize: 20,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDateField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context, controller, label),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          hintText: 'DD/MM/AAAA',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.green, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.green),
            onPressed: () => _selectDate(context, controller, label),
          ),
        ),
        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      // Formato yyyy-MM-dd para PostgreSQL
      controller.text = FormatService.formatDateForApi(picked);
    }
  }
}
