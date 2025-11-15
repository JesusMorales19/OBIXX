import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integradora/views/screens/login/login_view.dart';
import 'package:integradora/views/widgets/ChangePasswordDialog.dart';
import 'package:integradora/views/widgets/edit_dialog.dart';
import 'dart:io';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../../services/api_wrapper.dart';
import '../../../services/validation_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/logout_dialog.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_notification.dart';
import '../../../services/notification_service.dart';

class ProfileView extends StatefulWidget {
  final bool abrirPlanesPremium;
  
  const ProfileView({Key? key, this.abrirPlanesPremium = false}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  File? _image; // Foto seleccionada
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  String? _error;

  String? _email;
  String? _telefono;
  String? _username;
  String? _nombre;
  String? _apellido;
  String? _fechaNacimiento;
  int? _edad;
  String? _miembroDesde;
  String? _fotoPerfilBase64;
  
  // Estado premium
  bool _tienePremium = false;
  int? _idPlanActivo;
  String? _periodicidadActiva;


  // Función para seleccionar imagen
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64 = base64Encode(bytes);
      final actualizado = await _actualizarPerfil(fotoPerfilBase64: base64);
      if (actualizado) {
        setState(() {
          _image = File(pickedFile.path);
          _fotoPerfilBase64 = base64;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    
    // Abrir modal de planes premium si se solicita
    if (widget.abrirPlanesPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarModalPremium();
      });
    }
  }

  Future<void> _cargarPerfil({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final user = await StorageService.getUser();
    final emailGuardado = user?['email']?.toString();

    if (emailGuardado == null) {
      if (silent) {
        if (mounted) {
          CustomNotification.showError(
            context,
            'No se encontró la sesión del contratista.',
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No se encontró la sesión del contratista.';
        });
      }
      return;
    }

    final respuesta = await ApiWrapper.safeCall<Map<String, dynamic>>(
      call: () => ApiService.obtenerPerfilContratista(emailGuardado),
      errorMessage: 'Error al cargar perfil',
      showError: silent,
    );

    if (respuesta != null && respuesta['success'] == true) {
      final data = respuesta['data'] as Map<String, dynamic>?;
      if (data != null) {
        if (!mounted) return;
        setState(() {
          _email = data['email']?.toString() ?? emailGuardado;
          _telefono = data['telefono']?.toString();
          _username = data['username'];
          _nombre = data['nombre'];
          _apellido = data['apellido'];
          _fechaNacimiento = FormatService.formatDateStringForDisplay(data['fecha_nacimiento']?.toString());
          _edad = _calcularEdad(data['fecha_nacimiento']);
          _miembroDesde = _formatearMiembroDesde(data['created_at']);
          _fotoPerfilBase64 = data['foto_perfil'];
          _isLoading = false;
          _error = null;
        });
        
        // Cargar estado premium
        await _cargarEstadoPremium(emailGuardado);
      } else {
        if (!mounted) return;
        if (silent) {
          CustomNotification.showError(
            context,
            'No se pudo cargar la información del perfil.',
          );
        } else {
          setState(() {
            _isLoading = false;
            _error = 'No se pudo cargar la información del perfil.';
          });
        }
      }
    } else if (respuesta != null) {
      if (!mounted) return;
      if (silent) {
        CustomNotification.showError(
          context,
          respuesta['error']?.toString() ?? 'No se pudo cargar el perfil.',
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = respuesta['error']?.toString() ?? 'No se pudo cargar el perfil.';
        });
      }
    } else if (!silent) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar el perfil.';
      });
    }
  }

  Future<void> _cargarEstadoPremium(String email) async {
    final premiumResult = await ApiWrapper.safeCall<Map<String, dynamic>>(
      call: () => ApiService.verificarPremium(email),
      errorMessage: 'Error al cargar estado premium',
      showError: false,
    );
    
    if (premiumResult != null && mounted) {
      final data = premiumResult['data'] as Map<String, dynamic>? ?? premiumResult;
      setState(() {
        _tienePremium = data['tienePremium'] == true;
        _idPlanActivo = data['id_plan_activo'] as int?;
        _periodicidadActiva = data['periodicidad_activa'] as String?;
      });
    }
  }


  String _formatearMiembroDesde(dynamic valor) {
    if (valor == null) return 'No disponible';
    final texto = valor.toString();
    if (texto.isEmpty) return 'No disponible';
    try {
      final fecha = DateTime.parse(texto);
      try {
        final formatted = DateFormat('MMMM yyyy', 'es_MX').format(fecha);
        return _capitalizar(formatted);
      } catch (_) {
        final fallback = DateFormat('MMMM yyyy').format(fecha);
        return _capitalizar(fallback);
      }
    } catch (_) {
      return FormatService.formatDateStringForDisplay(valor?.toString());
    }
  }

  String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }

  int? _calcularEdad(dynamic fechaValor) {
    if (fechaValor == null) return null;
    try {
      final fecha = DateTime.parse(fechaValor.toString());
      final hoy = DateTime.now();
      int edad = hoy.year - fecha.year;
      if (hoy.month < fecha.month || (hoy.month == fecha.month && hoy.day < fecha.day)) {
        edad--;
      }
      return edad;
    } catch (_) {
      return null;
    }
  }

  ImageProvider<Object> _obtenerImagenPerfil() {
    if (_image != null) {
      return FileImage(_image!);
    }

    if (_fotoPerfilBase64 != null && _fotoPerfilBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_fotoPerfilBase64!));
      } catch (_) {
        // Si falla la decodificación, continuar abajo
      }
    }

    return const AssetImage('assets/images/albañil.png');
  }

  Future<bool> _actualizarPerfil({
    String? nuevoEmail,
    String? telefono,
    String? fotoPerfilBase64,
    String? passwordActual,
    String? passwordNueva,
  }) async {
    final emailActual = _email;
    if (emailActual == null || emailActual.isEmpty) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'No se pudo determinar el email del contratista.',
        );
      }
      return false;
    }

    final response = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
      call: () => ApiService.actualizarPerfilContratista(
        emailActual: emailActual,
        nuevoEmail: nuevoEmail,
        telefono: telefono,
        fotoPerfilBase64: fotoPerfilBase64,
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      ),
      errorMessage: 'Error al actualizar perfil',
    );

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>? ?? {};

      final storedUser = await StorageService.getUser();
      if (storedUser != null) {
        final Map<String, dynamic> updatedUser = Map<String, dynamic>.from(storedUser);
        final updatedEmail = data['email']?.toString();
        final updatedTelefono = data['telefono']?.toString();
        final updatedUsername = data['username']?.toString();
        final updatedFoto = data['foto_perfil']?.toString();
        if (updatedEmail != null) updatedUser['email'] = updatedEmail;
        if (updatedTelefono != null) updatedUser['telefono'] = updatedTelefono;
        if (updatedUsername != null) updatedUser['username'] = updatedUsername;
        if (updatedFoto != null) {
          updatedUser['foto_perfil'] = updatedFoto;
        }
        await StorageService.saveUser(updatedUser);
      }

      final cambioCorreo =
          nuevoEmail != null && nuevoEmail.toLowerCase() != emailActual.toLowerCase();

      if (mounted) {
        await _cargarPerfil(silent: true);
      }

      if (cambioCorreo) {
        _forzarReinicioSesion('Tu correo se actualizó correctamente. Vuelve a iniciar sesión con tu nuevo correo.');
        return true;
      }

      if (mounted) {
        CustomNotification.showSuccess(
          context,
          'Perfil actualizado correctamente.',
        );
      }

      return true;
    }

    return false;
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

  Future<void> _cancelarSuscripcion(BuildContext modalContext) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Suscripción'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar tu suscripción premium? '
          'Perderás acceso a todas las funciones premium inmediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
      call: () => ApiService.cancelarSuscripcion(
        emailContratista: _email!,
      ),
      errorMessage: 'Error al cancelar suscripción',
    );

    if (mounted) {
      Navigator.of(context).pop(); // Cerrar loading

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? result;
        
        // Actualizar estado
        await _cargarEstadoPremium(_email!);
        
        Navigator.of(modalContext).pop(); // Cerrar modal premium
        
        CustomNotification.showSuccess(
          context,
          'Suscripción premium cancelada exitosamente. Ya no tienes acceso a las funciones premium.',
        );
      }
    }
  }

  void _mostrarModalPremium() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        final beneficios = [
          'Registro de horas laborales por trabajador',
          'Ingreso y control de presupuestos por proyecto',
          'Gestión de pagos semanales a cada trabajador',
          'Descarga o impresión de nóminas por trabajo y trabajador',
        ];

        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.85,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Planes Premium para Contratistas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Desbloquea herramientas avanzadas para llevar un control profesional de tus proyectos y equipos.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      _buildPremiumPlanCard(
                        titulo: 'Plan Mensual',
                        precio: '\$250 MXN',
                        periodo: 'Cobro cada mes',
                        beneficios: beneficios,
                        badge: 'Ideal para probar',
                        esPlanActivo: _periodicidadActiva == 'mensual',
                        onTapContratar: () {
                          Navigator.of(modalContext).pop();
                          _mostrarFormularioPago(
                            idPlan: 'mensual',
                            tituloPlan: 'Plan Mensual',
                            precio: '\$250 MXN',
                            descripcionPeriodo: 'Cobro mensual, cancela cuando quieras.',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumPlanCard(
                        titulo: 'Plan Anual',
                        precio: '\$2,500 MXN',
                        periodo: 'Cobro una vez al año',
                        beneficios: beneficios,
                        badge: 'Ahorra 2 meses',
                        destacado: true,
                        esPlanActivo: _periodicidadActiva == 'anual',
                        onTapContratar: () {
                          Navigator.of(modalContext).pop();
                          _mostrarFormularioPago(
                            idPlan: 'anual',
                            tituloPlan: 'Plan Anual',
                            precio: '\$2,500 MXN',
                            descripcionPeriodo: 'Cobro anual con ahorro equivalente a 2 meses.',
                          );
                        },
                      ),
                      if (_tienePremium) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Suscripción Premium Activa',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tienes una suscripción ${_periodicidadActiva == 'mensual' ? 'mensual' : 'anual'} activa.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _cancelarSuscripcion(modalContext),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancelar Suscripción'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumPlanCard({
    required String titulo,
    required String precio,
    required String periodo,
    required List<String> beneficios,
    required VoidCallback onTapContratar,
    String? badge,
    bool destacado = false,
    bool esPlanActivo = false,
  }) {
    final Color primary = destacado ? const Color(0xFF1F4E79) : Colors.orange;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: destacado ? const Color(0xFF1F4E79) : Colors.orange.shade200,
          width: destacado ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: destacado
            ? LinearGradient(
                colors: [
                  const Color(0xFF1F4E79).withOpacity(0.92),
                  const Color(0xFF163a59).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFFFFBF2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: destacado ? Colors.white : primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: destacado ? primary : primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            titulo,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: destacado ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            precio,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: destacado ? Colors.white : primary,
            ),
          ),
          Text(
            periodo,
            style: TextStyle(
              color: destacado ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: beneficios
                .map(
                  (beneficio) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: destacado ? Colors.white : primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            beneficio,
                            style: TextStyle(
                              color: destacado ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: esPlanActivo ? null : onTapContratar,
              style: ElevatedButton.styleFrom(
                backgroundColor: esPlanActivo 
                    ? Colors.grey.shade400 
                    : (destacado ? Colors.white : primary),
                foregroundColor: esPlanActivo 
                    ? Colors.white 
                    : (destacado ? primary : Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                esPlanActivo ? 'Tiene plan activo' : 'Contratar plan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioPago({
    required String idPlan,
    required String tituloPlan,
    required String precio,
    required String descripcionPeriodo,
  }) {
    final nombreController = TextEditingController();
    final numeroController = TextEditingController();
    final fechaController = TextEditingController();
    final cvvController = TextEditingController();
    bool guardarTarjeta = false;
    bool autoRenovar = true;
    String tipoTarjeta = 'Desconocida';

    String detectarTipoTarjeta(String digits) {
      if (digits.isEmpty) return 'Desconocida';
      if (digits.startsWith('4')) return 'Visa';
      if (RegExp(r'^(5[1-5])').hasMatch(digits)) return 'Mastercard';
      if (RegExp(r'^(222[1-9]|22[3-9]\\d|2[3-6]\\d{2}|27[01]\\d|2720)').hasMatch(digits)) {
        return 'Mastercard';
      }
      if (RegExp(r'^(34|37)').hasMatch(digits)) return 'American Express';
      if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) return 'Discover';
      if (RegExp(r'^(36|38|30[0-5])').hasMatch(digits)) return 'Diners Club';
      if (RegExp(r'^(35)').hasMatch(digits)) return 'JCB';
      return 'Desconocida';
    }

    String formatearNumeroTarjeta(String digits, String tipo) {
      final buffer = StringBuffer();
      int maxLength = tipo == 'American Express' ? 15 : 16;
      if (tipo != 'American Express' && digits.length > 16) {
        maxLength = 19;
      }

      for (int i = 0; i < digits.length && i < maxLength; i++) {
        buffer.write(digits[i]);
        if (tipo == 'American Express') {
          if (i == 3 || i == 9) buffer.write(' ');
        } else {
          if (i % 4 == 3 && i != maxLength - 1 && i != digits.length - 1) {
            buffer.write(' ');
          }
        }
      }

      return buffer.toString().trimRight();
    }

    String formatearFecha(String input) {
      final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
      final buffer = StringBuffer();
      for (int i = 0; i < digits.length && i < 4; i++) {
        if (i == 2) buffer.write('/');
        buffer.write(digits[i]);
      }
      return buffer.toString();
    }

    bool fechaExpiracionValida(String valor) {
      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(valor)) return false;
      final partes = valor.split('/');
      final mes = FormatService.parseInt(partes[0]);
      final anio = FormatService.parseInt(partes[1]);
      if (mes < 1 || mes > 12) return false;
      final ahora = DateTime.now();
      final anioActual = ahora.year % 100;
      final mesActual = ahora.month;
      if (anio < anioActual) return false;
      if (anio == anioActual && mes < mesActual) return false;
      return true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Contratar $tituloPlan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$precio • $descripcionPeriodo',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nombre del titular',
                        hintText: 'Como aparece en la tarjeta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: numeroController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(19),
                      ],
                      onChanged: (value) {
                        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                        final detected = detectarTipoTarjeta(digits);
                        final formatted = formatearNumeroTarjeta(digits, detected);
                        if (formatted != numeroController.text) {
                          numeroController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                        setModalState(() {
                          tipoTarjeta = detected;
                        });
                      },
                      style: const TextStyle(
                        color: Colors.black87,
                        letterSpacing: 1.3,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Número de tarjeta',
                        hintText: '0000 0000 0000 0000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.credit_card),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.payment,
                            color: tipoTarjeta == 'Desconocida'
                                ? Colors.grey
                                : const Color(0xFF1F4E79),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tipo de tarjeta: $tipoTarjeta',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fechaController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (value) {
                              final digits = value.replaceAll(RegExp(r'\\D'), '');
                              final formatted = formatearFecha(digits);
                              if (formatted != fechaController.text) {
                                fechaController.value = TextEditingValue(
                                  text: formatted,
                                  selection:
                                      TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'MM/AA',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              prefixIcon: const Icon(Icons.date_range_outlined),
                            ),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Guardar tarjeta para próximos pagos'),
                      value: guardarTarjeta,
                      onChanged: (value) {
                        setModalState(() {
                          guardarTarjeta = value ?? false;
                          if (!guardarTarjeta) {
                            autoRenovar = false;
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activar pago automático al renovarse el plan'),
                      subtitle: const Text(
                        'Se cobrará automáticamente al finalizar el período.',
                      ),
                      value: autoRenovar,
                      onChanged: guardarTarjeta
                          ? (value) {
                              setModalState(() {
                                autoRenovar = value ?? false;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validar campos
                          final nombre = nombreController.text.trim();
                          final numeroSinEspacios = numeroController.text.replaceAll(RegExp(r'[^0-9]'), '');
                          final fecha = fechaController.text.trim();
                          final cvv = cvvController.text.trim();
                          
                          // Validaciones
                          if (nombre.isEmpty) {
                            CustomNotification.showError(
                              context,
                              'Por favor ingresa el nombre del titular.',
                            );
                            return;
                          }
                          
                          final longitudRequerida = tipoTarjeta == 'American Express' ? 15 : 16;
                          if (numeroSinEspacios.length < longitudRequerida) {
                            CustomNotification.showError(
                              context,
                              'El número de tarjeta debe tener al menos $longitudRequerida dígitos.',
                            );
                            return;
                          }
                          
                          if (!fechaExpiracionValida(fecha)) {
                            CustomNotification.showError(
                              context,
                              'Por favor ingresa una fecha de expiración válida (MM/AA).',
                            );
                            return;
                          }
                          
                          final cvvLongitudRequerida = tipoTarjeta == 'American Express' ? 4 : 3;
                          if (cvv.length < cvvLongitudRequerida) {
                            CustomNotification.showError(
                              context,
                              'El CVV debe tener al menos $cvvLongitudRequerida dígitos.',
                            );
                            return;
                          }

                          // Activar suscripción premium
                          final user = await StorageService.getUser();
                          final emailContratista = user?['email']?.toString();
                          
                          if (emailContratista == null) {
                            CustomNotification.showError(
                              context,
                              'No se encontró la sesión del contratista.',
                            );
                            return;
                          }

                          // Determinar ID del plan
                          final planId = idPlan == 'mensual' ? 1 : 2; // 1 = mensual, 2 = anual
                          
                          // Preparar método de pago si se guarda
                          Map<String, dynamic>? metodoPago;
                          if (guardarTarjeta) {
                            metodoPago = {
                              'marca': tipoTarjeta,
                              'ultimos4': numeroSinEspacios.length >= 4 ? numeroSinEspacios.substring(numeroSinEspacios.length - 4) : numeroSinEspacios,
                              'alias': 'Tarjeta ${tipoTarjeta}',
                              'token_pasarela': 'SIMULADO-${DateTime.now().millisecondsSinceEpoch}',
                            };
                          }

                          // Activar suscripción
                          final result = await ApiWrapper.safeCallWithResult<Map<String, dynamic>>(
                            call: () => ApiService.activarSuscripcion(
                              emailContratista: emailContratista,
                              idPlan: planId,
                              guardarTarjeta: guardarTarjeta,
                              autoRenovacion: autoRenovar,
                              metodoPago: metodoPago,
                            ),
                            errorMessage: 'Error al activar suscripción',
                          );

                          if (result['success'] == true) {
                            // Actualizar estado premium después de activar
                            await _cargarEstadoPremium(emailContratista);
                            
                            Navigator.of(modalContext).pop();
                            
                            // Si se abrió desde la vista de administración, regresar ahí
                            if (widget.abrirPlanesPremium) {
                              CustomNotification.showSuccess(
                                context,
                                '¡Suscripción premium activada exitosamente!\n'
                                'Ya puedes acceder a todas las funcionalidades premium.',
                              );
                              Navigator.of(context).pop(true); // Cerrar perfil y retornar true
                            } else {
                              CustomNotification.showSuccess(
                                context,
                                '¡Suscripción premium activada exitosamente!\n'
                                'Ya puedes acceder a todas las funcionalidades premium.',
                              );
                              // Recargar perfil para actualizar estado
                              await _cargarPerfil(silent: true);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4E79),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Confirmar suscripción',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = _email ?? 'Sin email';
    final displayTelefono = _telefono ?? 'Sin teléfono';
    final displayNombre = '${_nombre ?? ''} ${_apellido ?? ''}'.trim().isEmpty
        ? 'Sin nombre registrado'
        : '${_nombre ?? ''} ${_apellido ?? ''}'.trim();
    final displayUsername = _username ?? 'Sin usuario';
    final displayFechaNacimiento = _fechaNacimiento ?? 'No especificada';
    final displayEdad = _edad != null ? '${_edad!} años' : 'Edad no disponible';
    final displayMiembroDesde = _miembroDesde ?? 'No disponible';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(
        role: 'contratista',
        currentIndex: 3,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const HeaderBar(tipoUsuario: 'contratista'),
                    const SizedBox(height: 15),
                    const Divider(
                      color: Colors.black26,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 25),

                    // 🔹 Card principal (perfil)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.90,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 6),
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF1F4E79),
                                              width: 5,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 45,
                                            backgroundImage: _obtenerImagenPerfil(),
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
                                          padding: const EdgeInsets.all(5),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        displayUsername,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F4E79),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text.rich(
                                      TextSpan(
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Nombre: '),
                                          TextSpan(
                                            text: displayNombre,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fecha de nacimiento: $displayFechaNacimiento',
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Edad: $displayEdad',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Miembro desde $displayMiembroDesde',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔹 Datos de contacto
                    Container(
                      width: MediaQuery.of(context).size.width * 0.90,
                      padding: const EdgeInsets.all(15),
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
                            children: const [
                              Icon(Icons.message_outlined, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Datos de Contacto',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email editable
                          Row(
                            children: [
                              const Text(
                                'Email: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  displayEmail,
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () async {
                                  await EditDialog.show(
                                    context,
                                    'Email',
                                    displayEmail,
                                    (value) async {
                                      final nuevoEmail = value.trim();
                                      if (nuevoEmail.isEmpty) {
                                        CustomNotification.showError(
                                          context,
                                          'El email no puede estar vacío.',
                                        );
                                        return false;
                                      }
                                      if (!ValidationService.isValidEmail(nuevoEmail)) {
                                        CustomNotification.showError(
                                          context,
                                          ValidationService.getEmailError(nuevoEmail) ?? 'Ingresa un correo válido (ejemplo@dominio.com).',
                                        );
                                        return false;
                                      }
                                      if (_email != null &&
                                          nuevoEmail.toLowerCase() ==
                                              _email!.toLowerCase()) {
                                        return true;
                                      }
                                      return await _actualizarPerfil(
                                        nuevoEmail: nuevoEmail,
                                      );
                                    },
                                    keyboardType: TextInputType.emailAddress,
                                    textCapitalization: TextCapitalization.none,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Teléfono editable
                          Row(
                            children: [
                              const Text(
                                'Teléfono: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  displayTelefono,
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () async {
                                  await EditDialog.show(
                                    context,
                                    'Teléfono',
                                    displayTelefono,
                                    (value) async {
                                      final nuevoTelefono = value.trim();
                                      if (nuevoTelefono.isEmpty) {
                                        CustomNotification.showError(
                                          context,
                                          'El teléfono no puede estar vacío.',
                                        );
                                        return false;
                                      }
                                      if (!ValidationService.isValidPhone(nuevoTelefono)) {
                                        CustomNotification.showError(
                                          context,
                                          ValidationService.getPhoneError(nuevoTelefono) ?? 'Ingresa un número válido de 10 dígitos.',
                                        );
                                        return false;
                                      }
                                      if (_telefono != null && nuevoTelefono == _telefono) {
                                        return true;
                                      }
                                      return await _actualizarPerfil(
                                        telefono: nuevoTelefono,
                                      );
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

                    const SizedBox(height: 30),

                    // 🔹 Configuración de cuenta
                    Container(
                      width: MediaQuery.of(context).size.width * 0.90,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                          const Text(
                            'Configuración de Cuenta',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.star, color: Colors.amber),
                            title: const Text('Premium'),
                            onTap: _mostrarModalPremium,
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings, color: Colors.grey),
                            title: const Text('Cambiar contraseña'),
                            onTap: () {
                              ChangePasswordDialogModern.show(
                                context,
                                (currentPassword, newPassword) async {
                                  if (newPassword == currentPassword) {
                                    CustomNotification.showError(
                                      context,
                                      'La nueva contraseña debe ser distinta a la actual.',
                                    );
                                    return false;
                                  }
                                  return await _actualizarPerfil(
                                    passwordActual: currentPassword,
                                    passwordNueva: newPassword,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // LLAMAMOS AL MODAL DE LOGOUT
                                LogoutDialog.show(context, () {
                                  // Aquí tu lógica de cerrar sesión
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginView(),
                                    ),
                                    (route) => false,
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              ),
                              child: const Text(
                                'Cerrar sesión',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
      ),
    );
  }
}
