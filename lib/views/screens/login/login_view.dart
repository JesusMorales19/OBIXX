import 'package:flutter/material.dart';
import '../register/roles_view.dart';
import '../contratista/home_view.dart';
import '../trabajador/home_view.dart';

// ---------- IMPORTACIÓN DE COMPONENTES ----------
import '../../widgets/login_register/background_header.dart';
import '../../widgets/login_register/input_field.dart';
import '../../widgets/login_register/gradient_buttom.dart';
import '../../widgets/login_register/register_redirect_text.dart';
import '../../widgets/custom_notification.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/validation_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // 🔹 Controladores
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🔹 Estado para mostrar/ocultar contraseña
  bool _obscureText = true;

  // 🔹 Estados para errores de validación
  String? _emailOrUsernameError;
  String? _passwordError;

  // 🔹 Estado de carga
  bool _isLoading = false;

  // ---------- VALIDACIONES ----------
  void _validateEmailOrUsername(String value) {
    if (value.isEmpty) {
      setState(() => _emailOrUsernameError = 'Email o username es requerido');
    } else {
      setState(() => _emailOrUsernameError = null);
    }
  }

  void _validatePassword(String password) {
    setState(() => _passwordError = ValidationService.getPasswordError(password));
  }

  bool get _isFormValid {
    return _emailOrUsernameError == null &&
        _passwordError == null &&
        _emailOrUsernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        ValidationService.isValidPassword(_passwordController.text);
  }

  // ---------- FUNCIÓN LOGIN ----------
  Future<void> _handleLogin() async {
    String emailOrUsername = _emailOrUsernameController.text.trim();
    String password = _passwordController.text.trim();

    // Validar campos
    _validateEmailOrUsername(emailOrUsername);
    _validatePassword(password);

    // Si hay errores, no continuar
    if (_emailOrUsernameError != null || _passwordError != null) {
      return;
    }

    // Mostrar indicador de carga
    setState(() => _isLoading = true);

    try {
      // Llamar a la API de login (el backend detecta automáticamente el tipo de usuario)
      final resultado = await ApiService.login(
        emailOrUsername,
        password,
      );

      setState(() => _isLoading = false);

      if (resultado['success'] == true) {
        final data = resultado['data'];
        // El backend devuelve: { success: true, token: ..., user: ... }
        final token = data['token'];
        final user = data['user'];

        if (token == null || user == null) {
          if (context.mounted) {
            CustomNotification.showError(context, 'Error: Datos de respuesta inválidos');
          }
          return;
        }

        // Guardar token y datos del usuario
        await StorageService.saveToken(token);
        await StorageService.saveUser(user);

        final emailUsuario = user['email'] as String?;
        final tipoUsuario = user['tipoUsuario'] as String?;
        if (emailUsuario != null && tipoUsuario != null) {
          await NotificationService.instance.configureForUser(
            email: emailUsuario,
            tipoUsuario: tipoUsuario,
          );
        }

        // Solicitar permiso de ubicación y guardar coordenadas
        if (context.mounted) {
          await _solicitarYGuardarUbicacion(user);
        }

        // Mostrar mensaje de éxito
        if (context.mounted) {
          CustomNotification.showSuccess(context, 'Inicio de sesión exitoso');
          
          // Redirigir según el tipo de usuario obtenido del backend
          final tipoUsuario = user['tipoUsuario'];
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              if (tipoUsuario == 'contratista') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeViewContractor()),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeViewEmployee()),
                  (route) => false,
                );
              }
            }
          });
        }
      } else {
        // Mostrar error
        if (context.mounted) {
          CustomNotification.showError(
            context,
            resultado['error'] ?? 'Error al iniciar sesión',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        CustomNotification.showError(
          context,
          'Error de conexión: ${e.toString()}',
        );
      }
    }
  }

  /// Solicita permiso de ubicación y guarda las coordenadas en el backend
  Future<void> _solicitarYGuardarUbicacion(Map<String, dynamic> user) async {
    try {
      // Solicitar permiso de ubicación
      final tienePermiso = await LocationService.solicitarPermisoUbicacion();
      
      if (!tienePermiso) {
        // Mostrar diálogo preguntando si quiere habilitar ubicación
        if (context.mounted) {
          final habilitar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permiso de Ubicación'),
              content: const Text(
                'Para mostrarte trabajadores/trabajos cercanos, necesitamos acceso a tu ubicación.\n\n¿Deseas habilitar la ubicación?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Ahora no'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Habilitar'),
                ),
              ],
            ),
          );
          
          if (habilitar == true) {
            await LocationService.abrirConfiguracion();
          }
        }
        return;
      }

      // Obtener ubicación actual
      final position = await LocationService.obtenerUbicacionActual();
      
      if (position != null) {
        // Guardar ubicación en el backend
        final email = user['email'];
        final tipoUsuario = user['tipoUsuario'];
        
        final resultado = tipoUsuario == 'contratista'
            ? await ApiService.actualizarUbicacionContratista(
                email,
                position.latitude,
                position.longitude,
              )
            : await ApiService.actualizarUbicacionTrabajador(
                email,
                position.latitude,
                position.longitude,
              );

        if (resultado['success'] == true) {
          print('✅ Ubicación guardada: ${position.latitude}, ${position.longitude}');
        } else {
          print('⚠️ Error al guardar ubicación: ${resultado['error']}');
        }
      }
    } catch (e) {
      print('⚠️ Error al procesar ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---------- FONDO PRINCIPAL ----------
          Container(color: const Color(0xFFF9FAFB)),

          // ---------- FONDO AZUL SUPERIOR ----------
          const BackgroundHeader(),

          // ---------- CONTENIDO ----------
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_obix.png',
                    height: 280,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400,
                    child: Card(
                      elevation: 8,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            const Text(
                              "Welcome!!",
                              style: TextStyle(
                                color: Color(0xFFE67E22),
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 60),

                            // ---------- INPUT EMAIL/USERNAME ----------
                            InputField(
                              controller: _emailOrUsernameController,
                              hintText: 'Email o Username',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.text,
                              errorText: _emailOrUsernameError,
                              onChanged: (value) {
                                _validateEmailOrUsername(value.trim());
                              },
                            ),
                            const SizedBox(height: 40),

                            // ---------- INPUT PASSWORD ----------
                            InputField(
                              controller: _passwordController,
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscureText,
                              errorText: _passwordError,
                              toggleVisibility: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              onChanged: (value) {
                                _validatePassword(value);
                              },
                            ),
                            const SizedBox(height: 40),

                            // ---------- BOTÓN LOGIN ----------
                            _isLoading
                                ? const CircularProgressIndicator()
                                : GradientButton(
                                    text: "LOGIN",
                                    onPressed: _handleLogin,
                                    enabled: _isFormValid && !_isLoading,
                                  ),
                            const SizedBox(height: 60),

                            // ---------- TEXTO REGISTRO ----------
                            RegisterRedirectText(
                              text: "Don't have account? ",
                              actionText: "Register",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RolesView(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
