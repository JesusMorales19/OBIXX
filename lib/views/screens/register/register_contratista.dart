import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/login_register/background_header.dart';
import '../../widgets/login_register/input_field.dart';
import '../../widgets/login_register/date_field.dart';
import '../../widgets/login_register/build_drop_down.dart' show CustomDropdown;
import '../../widgets/login_register/build_next_buttom.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/image_picker_modal.dart';
import '../../../models/contratista_model.dart';
import '../../../services/api_service.dart';
import '../../../services/validation_service.dart';
import '../../../utils/image_utils.dart';
import '../../../utils/context_helper.dart';
import '../login/login_view.dart';
import '../../../core/utils/responsive.dart';

class RegisterContratista extends StatefulWidget {
  const RegisterContratista({super.key});

  @override
  State<RegisterContratista> createState() => _RegisterContratistaState();
}

class _RegisterContratistaState extends State<RegisterContratista> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Controllers de los campos
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final fechaController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Ocultar/mostrar contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Ancho uniforme para todos los campos (se calculará dinámicamente)
  double _getFieldWidth(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return double.infinity;
    } else if (Responsive.isTablet(context)) {
      return 400;
    } else {
      return 450;
    }
  }

  // Estados para errores de validación
  String? _nombreError;
  String? _apellidoError;
  String? _fechaError;
  String? _correoError;
  String? _telefonoError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generoSeleccionado;
  
  // Imagen de perfil
  File? _imagenSeleccionada;
  String? _fotoBase64;

  // ---------- VALIDACIONES ----------
  bool get _isStep1Valid {
    return ValidationService.isValidName(nombreController.text) &&
        ValidationService.isValidName(apellidoController.text) &&
        fechaController.text.trim().isNotEmpty &&
        ValidationService.isValidDate(fechaController.text.trim());
  }

  bool get _isStep2Valid {
    return correoController.text.trim().isNotEmpty &&
        ValidationService.isValidEmail(correoController.text.trim()) &&
        _generoSeleccionado != null &&
        _generoSeleccionado!.isNotEmpty &&
        telefonoController.text.trim().isNotEmpty &&
        ValidationService.isValidPhone(telefonoController.text.trim()) &&
        passwordController.text.isNotEmpty &&
        ValidationService.isValidPassword(passwordController.text) &&
        confirmPasswordController.text.isNotEmpty &&
        passwordController.text == confirmPasswordController.text;
  }

  void _validateStep1() {
    bool isValid = true;

    // Validar nombre
    setState(() => _nombreError = ValidationService.getNameError(nombreController.text, fieldName: 'El nombre'));
    if (_nombreError != null) isValid = false;

    // Validar apellido
    setState(() => _apellidoError = ValidationService.getNameError(apellidoController.text, fieldName: 'El apellido'));
    if (_apellidoError != null) isValid = false;

    // Validar fecha
    setState(() => _fechaError = ValidationService.getDateError(fechaController.text));
    if (_fechaError != null) isValid = false;

    if (isValid && _currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _validateStep2() {
    bool isValid = true;

    // Validar correo
    setState(() => _correoError = ValidationService.getEmailError(correoController.text));
    if (_correoError != null) isValid = false;

    // Validar género
    if (_generoSeleccionado == null || _generoSeleccionado!.isEmpty) {
      CustomNotification.showError(context, 'Por favor selecciona un género');
      isValid = false;
    }

    // Validar teléfono
    setState(() => _telefonoError = ValidationService.getPhoneError(telefonoController.text));
    if (_telefonoError != null) isValid = false;

    // Validar contraseña
    setState(() => _passwordError = ValidationService.getPasswordError(passwordController.text));
    if (_passwordError != null) isValid = false;

    // Validar confirmación de contraseña
    if (confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirma tu contraseña');
      isValid = false;
    } else if (passwordController.text != confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Las contraseñas no coinciden');
      isValid = false;
    } else {
      setState(() => _confirmPasswordError = null);
    }

    if (isValid) {
      _registrarContratista();
    }
  }

  Future<void> _registrarContratista() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Crear el modelo de contratista
      final contratista = ContratistaModel(
        nombre: nombreController.text.trim(),
        apellido: apellidoController.text.trim(),
        fechaNacimiento: fechaController.text.trim(),
        email: correoController.text.trim(),
        genero: _generoSeleccionado ?? '',
        telefono: telefonoController.text.trim(),
        password: passwordController.text,
        fotoBase64: _fotoBase64,
      );

      // Llamar al servicio de API
      final resultado = await ApiService.registrarContratista(contratista);

      // Cerrar el indicador de carga
      ContextHelper.safePop(context);

      if (resultado['success'] == true) {
        ContextHelper.safeShowSuccess(context, 'Registro exitoso');
        // Esperar un momento y luego redirigir al login
        Future.delayed(const Duration(seconds: 1), () {
          ContextHelper.safeNavigateAndRemoveUntil(context, const LoginView());
        });
      } else {
        ContextHelper.safeShowError(
          context,
          resultado['error'] ?? 'Error al registrar',
        );
      }
    } catch (e) {
      // Cerrar el indicador de carga
      ContextHelper.safePop(context);
      ContextHelper.safeShowError(
        context,
        'Error de conexión. Verifica que el servidor esté corriendo.',
      );
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => _passwordError = 'La contraseña es requerida');
    } else if (password.length < 8) {
      setState(() => _passwordError = 'La contraseña debe tener más de 8 caracteres');
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() => _passwordError = 'La contraseña debe contener al menos una mayúscula');
    } else if (!password.contains(RegExp(r'[a-z]'))) {
      setState(() => _passwordError = 'La contraseña debe contener al menos una minúscula');
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => _passwordError = 'La contraseña debe contener al menos un número');
    } else {
      setState(() => _passwordError = null);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      _validateStep1();
    }
  }

  // Función para mostrar el modal de selección de imagen
  Future<void> _mostrarModalSeleccionImagen() async {
    // Primero verificar y solicitar permisos
    final tienePermisos = await ImageUtils.verificarPermisos();
    
    if (!tienePermisos) {
      final permisosConcedidos = await ImageUtils.solicitarPermisos();
      
      if (!permisosConcedidos) {
        ContextHelper.safeShowError(
          context,
          'Se necesitan permisos de cámara y galería para seleccionar una imagen',
        );
        
        // Preguntar si quiere abrir configuración
        final abrirConfig = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permisos requeridos'),
            content: const Text(
              'Para seleccionar una imagen necesitas permitir el acceso a la cámara y galería. ¿Deseas abrir la configuración?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        );
        
        if (abrirConfig == true) {
          await ImageUtils.abrirConfiguracion();
        }
        return;
      }
    }

    // Mostrar modal de selección
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => ImagePickerModal(
          onCameraTap: _tomarFoto,
          onGalleryTap: _seleccionarDeGaleria,
        ),
      );
    }
  }

  // Función para tomar foto con la cámara
  Future<void> _tomarFoto() async {
    try {
      final imagen = await ImageUtils.tomarFoto();
      if (imagen != null) {
        final base64 = await ImageUtils.imagenABase64(imagen);
        if (base64 != null) {
          if (mounted) {
            setState(() {
              _imagenSeleccionada = File(imagen.path);
              _fotoBase64 = base64;
            });
          }
        } else {
          ContextHelper.safeShowError(context, 'Error al procesar la imagen');
        }
      }
    } catch (e) {
      ContextHelper.safeShowError(context, 'Error al tomar la foto: $e');
    }
  }

  // Función para seleccionar de la galería
  Future<void> _seleccionarDeGaleria() async {
    try {
      final imagen = await ImageUtils.seleccionarDeGaleria();
      if (imagen != null) {
        final base64 = await ImageUtils.imagenABase64(imagen);
        if (base64 != null) {
          if (mounted) {
            setState(() {
              _imagenSeleccionada = File(imagen.path);
              _fotoBase64 = base64;
            });
          }
        } else {
          ContextHelper.safeShowError(context, 'Error al procesar la imagen');
        }
      }
    } catch (e) {
      ContextHelper.safeShowError(context, 'Error al seleccionar la imagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFF9FAFB)),
          const BackgroundHeader(),
          SafeArea(
            child: ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.getHorizontalPadding(context),
                vertical: 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 20,
                        tablet: 30,
                        desktop: 40,
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo_obix.png',
                      height: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 180,
                        tablet: 230,
                        desktop: 280,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 10,
                        tablet: 15,
                        desktop: 20,
                      ),
                    ),
                    Card(
                      elevation: 10,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          Responsive.getResponsiveSpacing(
                            context,
                            mobile: 20,
                            tablet: 25,
                            desktop: 30,
                          ),
                        ),
                        child: SizedBox(
                          width: Responsive.isMobile(context) 
                              ? double.infinity 
                              : 500,
                          height: Responsive.getResponsiveSpacing(
                            context,
                            mobile: 550,
                            tablet: 600,
                            desktop: 650,
                          ),
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStep1(),
                              _buildStep2(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 30,
                        tablet: 35,
                        desktop: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Text(
          "Registro de Contratista",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFE67E22),
            fontSize: Responsive.getResponsiveFontSize(
              context,
              mobile: 28,
              tablet: 32,
              desktop: 34,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        Container(
          width: double.infinity,
          height: 2,
          color: Colors.grey[300],
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 15,
            tablet: 20,
            desktop: 25,
          ),
        ),
        GestureDetector(
          onTap: _mostrarModalSeleccionImagen,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _imagenSeleccionada != null
                    ? FileImage(_imagenSeleccionada!)
                    : null,
                child: _imagenSeleccionada == null
                    ? const Icon(Icons.camera_alt, color: Colors.white, size: 55)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.getResponsiveSpacing(
                      context,
                      mobile: 6,
                      tablet: 7,
                      desktop: 8,
                    ),
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE67E22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 19,
                      desktop: 20,
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
            mobile: 15,
            tablet: 20,
            desktop: 25,
          ),
        ),
        InputField(
          controller: nombreController,
          hintText: "Nombre",
          icon: Icons.person,
          width: _getFieldWidth(context),
          errorText: _nombreError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && value.trim().length >= 2) {
              setState(() => _nombreError = null);
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 15,
            tablet: 20,
            desktop: 25,
          ),
        ),
        InputField(
          controller: apellidoController,
          hintText: "Apellido",
          icon: Icons.person_outline,
          width: _getFieldWidth(context),
          errorText: _apellidoError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && value.trim().length >= 2) {
              setState(() => _apellidoError = null);
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 15,
            tablet: 20,
            desktop: 25,
          ),
        ),
        DateField(
          controller: fechaController,
          hintText: "Fecha de Nacimiento (DD/MM/AAAA)",
          icon: Icons.calendar_today,
          width: _getFieldWidth(context),
          errorText: _fechaError,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          onChanged: () {
            if (fechaController.text.trim().isNotEmpty) {
              setState(() => _fechaError = null);
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 30,
            tablet: 35,
            desktop: 40,
          ),
        ),
        NextButton(
          text: "Siguiente",
          onPressed: _nextStep,
          enabled: _isStep1Valid,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        InputField(
          controller: correoController,
          hintText: "Correo",
          icon: Icons.email,
          width: _getFieldWidth(context),
          keyboardType: TextInputType.emailAddress,
          errorText: _correoError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && ValidationService.isValidEmail(value.trim())) {
              setState(() => _correoError = null);
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 20,
            tablet: 25,
            desktop: 30,
          ),
        ),
        CustomDropdown(
          label: "Género",
          items: ["Masculino", "Femenino"],
          width: _getFieldWidth(context),
          onChanged: (value) {
            setState(() => _generoSeleccionado = value);
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 20,
            tablet: 25,
            desktop: 30,
          ),
        ),
        InputField(
          controller: telefonoController,
          hintText: "Teléfono (10 dígitos)",
          icon: Icons.phone,
          width: _getFieldWidth(context),
          keyboardType: TextInputType.phone,
          errorText: _telefonoError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && ValidationService.isValidPhone(value.trim())) {
              setState(() => _telefonoError = null);
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 20,
            tablet: 25,
            desktop: 30,
          ),
        ),
        InputField(
          controller: passwordController,
          hintText: "Contraseña",
          icon: Icons.lock,
          isPassword: true,
          obscureText: _obscurePassword,
          errorText: _passwordError,
          toggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          width: _getFieldWidth(context),
          onChanged: (value) {
            _validatePassword(value);
            if (confirmPasswordController.text.isNotEmpty) {
              if (value == confirmPasswordController.text) {
                setState(() => _confirmPasswordError = null);
              } else {
                setState(() => _confirmPasswordError = 'Las contraseñas no coinciden');
              }
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 20,
            tablet: 25,
            desktop: 30,
          ),
        ),
        InputField(
          controller: confirmPasswordController,
          hintText: "Confirmar contraseña",
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          errorText: _confirmPasswordError,
          toggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          width: _getFieldWidth(context),
          onChanged: (value) {
            if (value == passwordController.text) {
              setState(() => _confirmPasswordError = null);
            } else {
              setState(() => _confirmPasswordError = 'Las contraseñas no coinciden');
            }
          },
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 40,
            tablet: 50,
            desktop: 60,
          ),
        ),
        NextButton(
          text: "Registrar",
          onPressed: _validateStep2,
          enabled: _isStep2Valid,
        ),
      ],
    );
  }
}
