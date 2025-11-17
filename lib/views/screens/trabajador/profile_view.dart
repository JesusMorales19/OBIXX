import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integradora/views/widgets/ChangePasswordDialog.dart';
import 'package:integradora/views/widgets/trabajador/profile_view/reviews_modal.dart';
import 'package:integradora/views/widgets/edit_dialog.dart';
import 'package:intl/intl.dart';
import 'package:integradora/services/api_service.dart';
import 'package:integradora/services/storage_service.dart';
import 'package:integradora/services/format_service.dart';
import 'package:integradora/services/validation_service.dart';
import '../login/login_view.dart'; // Asegúrate que la ruta sea correcta
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/logout_dialog.dart'; // Tu modal de confirmación de logout
import '../../widgets/custom_notification.dart';
import '../../../services/notification_service.dart';
import '../../../core/utils/responsive.dart';

class ProfileViewEmployees extends StatefulWidget {
  const ProfileViewEmployees({Key? key}) : super(key: key);

  @override
  State<ProfileViewEmployees> createState() => _ProfileViewEmployeesState();
}

class _ProfileViewEmployeesState extends State<ProfileViewEmployees> {
  File? _image;
  String? _fotoPerfilBase64;
  final ImagePicker _picker = ImagePicker();

  Map<String, String>? _categoriasCache;

  // Datos del perfil
  String email = '';
  String telefono = '';
  String descripcion = 'Sin descripción disponible.';
  int edad = 0;
  DateTime? fechaNacimiento;
  double calificacion = 0.0;
  String nombre = '';
  String apellido = '';
  String username = '';
  String categoria = '';
  DateTime? miembroDesde;

  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _fetchPerfilTrabajador();
  }

  Future<void> _fetchPerfilTrabajador({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = await StorageService.getUser();
      final correo = user?['email']?.toString() ?? user?['correo']?.toString();

      if (correo == null) {
        if (silent) {
          if (mounted) {
            CustomNotification.showError(
              context,
              'No se encontró una sesión de trabajador activa.',
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No se encontró una sesión de trabajador activa.';
          });
        }
        return;
      }

      final perfilResponse = await ApiService.obtenerPerfilTrabajador(correo);

      if (perfilResponse['success'] == true) {
        final data = perfilResponse['data'] as Map<String, dynamic>;

        final fechaStr = data['fecha_nacimiento']?.toString();
        DateTime? fecha;
        if (fechaStr != null && fechaStr.isNotEmpty) {
          fecha = DateTime.tryParse(fechaStr);
        }

        final createdAtStr = data['created_at']?.toString();
        DateTime? createdAt;
        if (createdAtStr != null && createdAtStr.isNotEmpty) {
          createdAt = DateTime.tryParse(createdAtStr);
        }

        final desc = data['descripcion'];

        final rawCategoria = data['categoria']?.toString() ?? categoria;
        final categoriaResuelta = await _resolverCategoria(rawCategoria);

        if (!mounted) return;
        setState(() {
          email = data['email']?.toString() ?? correo;
          telefono = data['telefono']?.toString() ?? telefono;
          if (desc is String && desc.trim().isNotEmpty) {
            descripcion = desc.trim();
          }

          fechaNacimiento = fecha;
          edad = fecha != null ? _calculateAge(fecha) : edad;
          calificacion = FormatService.parseDouble(data['calificacion_promedio']);

          nombre = data['nombre']?.toString() ?? nombre;
          apellido = data['apellido']?.toString() ?? apellido;
          username = data['username']?.toString() ?? username;
          categoria = categoriaResuelta;

          miembroDesde = createdAt;
          _fotoPerfilBase64 = data['foto_perfil']?.toString();
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        if (!mounted) return;
        if (silent) {
          CustomNotification.showError(
            context,
            perfilResponse['error']?.toString() ?? 'No se pudo cargar el perfil.',
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                perfilResponse['error']?.toString() ?? 'No se pudo cargar el perfil.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (silent) {
        CustomNotification.showError(
          context,
          'Error al cargar el perfil: $e',
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar el perfil: $e';
        });
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _capitalizar(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<String> _resolverCategoria(String raw) async {
    if (raw.isEmpty) return 'Sin categoría';

    final parsed = FormatService.parseInt(raw);
    if (parsed == 0 && raw.isNotEmpty) {
      return _capitalizar(raw);
    }

    if (_categoriasCache == null) {
      await _cargarCategorias();
    }

    final nombre = _categoriasCache?[parsed.toString()];
    if (nombre != null && nombre.isNotEmpty) {
      return nombre;
    }

    return 'Categoría $parsed';
  }

  Future<void> _cargarCategorias() async {
    try {
      final resp = await ApiService.getCategorias();
      if (resp['success'] == true && resp['data'] is List) {
        final mapa = <String, String>{};
        for (final item in resp['data']) {
          if (item is Map<String, dynamic>) {
            final id = item['id_categoria']?.toString();
            final nombre = item['nombre']?.toString();
            if (id != null && nombre != null && nombre.isNotEmpty) {
              mapa[id] = _capitalizar(nombre);
            }
          }
        }
        if (mapa.isNotEmpty) {
          _categoriasCache = mapa;
          return;
        }
      }
    } catch (_) {
      // Ignoramos errores, usaremos fallback abajo
    }

    _categoriasCache = const {
      '1': 'Albañil',
      '2': 'Carpintero',
      '3': 'Electricista',
      '4': 'Plomero',
      '5': 'Pintor',
    };
  }

  ImageProvider _getProfileImage() {
    if (_image != null) {
      return FileImage(_image!);
    }
    if (_fotoPerfilBase64 != null && _fotoPerfilBase64!.isNotEmpty) {
      try {
        final cleaned = _fotoPerfilBase64!.contains(',')
            ? _fotoPerfilBase64!.split(',').last
            : _fotoPerfilBase64!;
        final bytes = base64Decode(cleaned);
        return MemoryImage(bytes);
      } catch (_) {
        // Ignorar y usar la imagen por defecto
      }
    }
    return const AssetImage('assets/images/albañil.png');
  }

  // 🔹 Función para seleccionar imagen de perfil
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64 = base64Encode(bytes);
      final actualizado = await _actualizarPerfil(
        fotoPerfilBase64: base64,
        mostrarExito: false,
      );
      if (actualizado) {
        if (mounted) {
          setState(() {
            _image = File(pickedFile.path);
            _fotoPerfilBase64 = base64;
          });
          CustomNotification.showSuccess(
            context,
            'Foto de perfil actualizada correctamente.',
          );
        }
      }
    }
  }

  // 🔹 Función para mostrar estrellas de calificación
  Widget _buildStars() {
    final fullStars = calificacion.floor();
    final hasHalf = (calificacion - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == fullStars && hasHalf) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 18);
      }),
    );
  }

  Future<bool> _actualizarPerfil({
    String? nuevoEmail,
    String? telefonoNuevo,
    String? descripcionNueva,
    String? fotoPerfilBase64,
    String? passwordActual,
    String? passwordNueva,
    bool mostrarExito = true,
  }) async {
    final emailActual =
        email.isNotEmpty ? email : (await StorageService.getUser())?['email']?.toString();

    if (emailActual == null || emailActual.isEmpty) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'No se pudo determinar el email actual del trabajador.',
        );
      }
      return false;
    }

    try {
      final response = await ApiService.actualizarPerfilTrabajador(
        emailActual: emailActual,
        nuevoEmail: nuevoEmail,
        telefono: telefonoNuevo,
        descripcion: descripcionNueva,
        fotoPerfilBase64: fotoPerfilBase64,
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;

        if (data != null && mounted) {
          setState(() {
            email = data['email']?.toString() ?? email;
            telefono = data['telefono']?.toString() ?? telefono;
            final desc = data['descripcion'];
            descripcion = (desc is String && desc.trim().isNotEmpty)
                ? desc.trim()
                : 'Sin descripción disponible.';
            username = data['username']?.toString() ?? username;
            _fotoPerfilBase64 = data['foto_perfil']?.toString() ?? _fotoPerfilBase64;
          });

          final storedUser = await StorageService.getUser();
          if (storedUser != null) {
            final updated = Map<String, dynamic>.from(storedUser);
            updated['email'] = data['email'] ?? updated['email'];
            updated['username'] = data['username'] ?? updated['username'];
            if (telefonoNuevo != null) {
              updated['telefono'] = data['telefono'];
            }
            if (descripcionNueva != null) {
              updated['descripcion'] = data['descripcion'];
            }
            if (fotoPerfilBase64 != null) {
              updated['foto_perfil'] = data['foto_perfil'];
            }
            await StorageService.saveUser(updated);
          }
        }

        if (mounted) {
          await _fetchPerfilTrabajador(silent: true);
        }

        if (nuevoEmail != null && nuevoEmail != emailActual) {
          _forzarReinicioSesion(
            'Tu correo se actualizó correctamente. Vuelve a iniciar sesión con tu nuevo correo.',
          );
          return true;
        }

        if (mounted && mostrarExito) {
          CustomNotification.showSuccess(
            context,
            'Perfil actualizado correctamente.',
          );
        }

        return true;
      } else {
        if (mounted) {
          CustomNotification.showError(
            context,
            response['error']?.toString() ?? 'No se pudo actualizar el perfil.',
          );
        }
        return false;
      }
    } catch (error) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error al actualizar el perfil: $error',
        );
      }
      return false;
    }
  }

  void _forzarReinicioSesion(String mensaje) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await StorageService.clearSession();
      await NotificationService.instance.clearSession();
      if (!mounted) return;
      CustomNotification.showInfo(context, mensaje);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = fechaNacimiento != null
        ? DateFormat('dd/MM/yyyy').format(fechaNacimiento!)
        : '--/--/----';
    String miembroDesdeTexto = '--';
    if (miembroDesde != null) {
      try {
        final formatted = DateFormat('MMMM yyyy', 'es_MX').format(miembroDesde!);
        miembroDesdeTexto = _capitalizar(formatted);
      } catch (_) {
        miembroDesdeTexto =
            _capitalizar(DateFormat('MMMM yyyy').format(miembroDesde!));
      }
    }
    final nombreCompleto =
        [nombre, apellido].where((element) => element.isNotEmpty).join(' ');
    final categoriaLabel = categoria.isNotEmpty ? categoria : 'Sin categoría';
    final usernameLabel = username.isNotEmpty ? username : 'Usuario';
    final emailLabel = email.isNotEmpty ? email : 'Sin correo';
    final telefonoLabel = telefono.isNotEmpty ? telefono : 'Sin teléfono';
    final edadTexto = edad > 0 ? '$edad años' : 'Sin datos';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar:
            const CustomBottomNav(role: 'trabajador', currentIndex: 2),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar:
            const CustomBottomNav(role: 'trabajador', currentIndex: 2),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(
              Responsive.getResponsiveSpacing(
                context,
                mobile: 18,
                tablet: 21,
                desktop: 24,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 42,
                    tablet: 45,
                    desktop: 48,
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
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _fetchPerfilTrabajador();
                  },
                  child: Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(role: 'trabajador', currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const HeaderBar(tipoUsuario: 'trabajador'),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 15,
                ),
              ),
              Divider(
                color: Colors.black26,
                thickness: 1,
                indent: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 15,
                  tablet: 17,
                  desktop: 20,
                ),
                endIndent: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 15,
                  tablet: 17,
                  desktop: 20,
                ),
              ),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 15,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
              Text(
                'Mi Perfil',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 26,
                    tablet: 28,
                    desktop: 30,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 25,
                ),
              ),

              // 🔹 Card principal (perfil)
              Container(
                width: MediaQuery.of(context).size.width * 0.90,
                padding: EdgeInsets.all(
                  Responsive.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 15,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              height: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 5,
                                tablet: 5.5,
                                desktop: 6,
                              ),
                            ),
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1F4E79),
                                        width: Responsive.getResponsiveSpacing(
                                          context,
                                          mobile: 4,
                                          tablet: 4.5,
                                          desktop: 5,
                                        ),
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: Responsive.getResponsiveFontSize(
                                        context,
                                        mobile: 40,
                                        tablet: 42,
                                        desktop: 45,
                                      ),
                                      backgroundImage: _getProfileImage(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(
                                      Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 4,
                                        tablet: 4.5,
                                        desktop: 5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: Responsive.getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 17,
                                        desktop: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 8,
                                tablet: 9,
                                desktop: 10,
                              ),
                            ),
                            Text(
                              categoriaLabel,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 15,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  usernameLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveFontSize(
                                      context,
                                      mobile: 18,
                                      tablet: 19,
                                      desktop: 20,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F4E79),
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
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Nombre: ',
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveFontSize(
                                          context,
                                          mobile: 12,
                                          tablet: 13,
                                          desktop: 14,
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: nombreCompleto.isNotEmpty
                                          ? nombreCompleto
                                          : 'Sin nombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: Responsive.getResponsiveFontSize(
                                          context,
                                          mobile: 12,
                                          tablet: 13,
                                          desktop: 14,
                                        ),
                                      ),
                                    ),
                                  ],
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
                              Text(
                                'Fecha de nacimiento: $fechaStr',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveFontSize(
                                    context,
                                    mobile: 12,
                                    tablet: 13,
                                    desktop: 14,
                                  ),
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.getResponsiveSpacing(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 15,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edad: $edadTexto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.getResponsiveFontSize(
                                        context,
                                        mobile: 12,
                                        tablet: 13,
                                        desktop: 14,
                                      ),
                                      color: Colors.black,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildStars(),
                                      TextButton(
                                        onPressed: email.isEmpty
                                            ? null
                                            : () => ReviewsModal.show(
                                                  context,
                                                  emailTrabajador: email,
                                                  promedioActual: calificacion,
                                                ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(
                                            Responsive.getResponsiveSpacing(
                                              context,
                                              mobile: 45,
                                              tablet: 47,
                                              desktop: 50,
                                            ),
                                            Responsive.getResponsiveSpacing(
                                              context,
                                              mobile: 18,
                                              tablet: 19,
                                              desktop: 20,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'ver reseñas',
                                          style: TextStyle(
                                            fontSize: Responsive.getResponsiveFontSize(
                                              context,
                                              mobile: 11,
                                              tablet: 11.5,
                                              desktop: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 8,
                        tablet: 9,
                        desktop: 10,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Miembro desde $miembroDesdeTexto',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 11,
                            tablet: 11.5,
                            desktop: 12,
                          ),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 25,
                  tablet: 27,
                  desktop: 30,
                ),
              ),

              // 🔹 Datos de contacto
              Container(
                width: MediaQuery.of(context).size.width * 0.90,
                padding: EdgeInsets.all(
                  Responsive.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 15,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          color: Colors.blue,
                          size: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 21,
                            desktop: 22,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 7,
                            desktop: 8,
                          ),
                        ),
                        Text(
                          'Datos de Contacto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 15,
                              desktop: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 10,
                        tablet: 11,
                        desktop: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Email: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            emailLabel,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                          ),
                          onPressed: () async {
                            await EditDialog.show(
                              context,
                              'Email',
                              emailLabel,
                              (value) async {
                                final nuevo = value.trim();
                                if (nuevo.isEmpty) {
                                  CustomNotification.showError(
                                    context,
                                    'El email no puede estar vacío.',
                                  );
                                  return false;
                                }
                                if (!ValidationService.isValidEmail(nuevo)) {
                                  CustomNotification.showError(
                                    context,
                                    ValidationService.getEmailError(nuevo) ?? 'Ingresa un correo válido (ejemplo@dominio.com).',
                                  );
                                  return false;
                                }
                                if (nuevo.toLowerCase() == email.toLowerCase()) {
                                  return true;
                                }
                                return await _actualizarPerfil(nuevoEmail: nuevo);
                              },
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                            );
                          },
                        ),
                      ],
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
                        Text(
                          'Teléfono: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            telefonoLabel,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                          ),
                          onPressed: () async {
                            await EditDialog.show(
                              context,
                              'Teléfono',
                              telefonoLabel,
                              (value) async {
                                final nuevo = value.trim();
                                if (nuevo.isEmpty) {
                                  CustomNotification.showError(
                                    context,
                                    'El teléfono no puede estar vacío.',
                                  );
                                  return false;
                                }
                                if (!ValidationService.isValidPhone(nuevo)) {
                                  CustomNotification.showError(
                                    context,
                                    ValidationService.getPhoneError(nuevo) ?? 'Ingresa un número válido de 10 dígitos.',
                                  );
                                  return false;
                                }
                                if (nuevo == telefono) return true;
                                return await _actualizarPerfil(telefonoNuevo: nuevo);
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              textCapitalization: TextCapitalization.none,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 15,
                  tablet: 18,
                  desktop: 20,
                ),
              ),

              // 🔹 Descripción
              Container(
                width: MediaQuery.of(context).size.width * 0.90,
                padding: EdgeInsets.all(
                  Responsive.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 15,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Colors.blue,
                          size: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 21,
                            desktop: 22,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 6,
                            tablet: 7,
                            desktop: 8,
                          ),
                        ),
                        Text(
                          'Descripción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 15,
                              desktop: 16,
                            ),
                          ),
                        ),
                      ],
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
                          child: Text(
                            descripcion,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                          ),
                          onPressed: () async {
                            await EditDialog.show(
                              context,
                              'Descripción',
                              descripcion,
                              (value) async {
                                final nueva = value.trim();
                                return await _actualizarPerfil(
                                  descripcionNueva: nueva,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 25,
                  tablet: 27,
                  desktop: 30,
                ),
              ),

              // 🔹 Configuración de cuenta / Logout
              Container(
                width: MediaQuery.of(context).size.width * 0.90,
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 9,
                    desktop: 10,
                  ),
                  horizontal: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 15,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de Cuenta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: Colors.grey,
                        size: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 21,
                          desktop: 22,
                        ),
                      ),
                      title: Text(
                        'Cambiar contraseña',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                        ),
                      ),
                      onTap: () {
                        ChangePasswordDialogModern.show(
                          context,
                          (currentPassword, newPassword) async {
                            final ok = await _actualizarPerfil(
                              passwordActual: currentPassword,
                              passwordNueva: newPassword,
                              mostrarExito: false,
                            );
                            if (ok && mounted) {
                              CustomNotification.showSuccess(
                                context,
                                'Contraseña cambiada correctamente.',
                              );
                            }
                            return ok;
                          },
                        );
                      },
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 8,
                        tablet: 9,
                        desktop: 10,
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          LogoutDialog.show(context, () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginView(),
                                ),
                                (route) => false,
                              );
                            });
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 35,
                              tablet: 37,
                              desktop: 40,
                            ),
                            vertical: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 15,
                              desktop: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
