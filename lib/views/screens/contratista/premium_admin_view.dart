import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/format_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/header_bar.dart';
import '../../widgets/custom_notification.dart';
import 'modals/premium_modals.dart';
import 'profile_view.dart';
import '../../../core/utils/responsive.dart';

class PremiumAdminView extends StatefulWidget {
  const PremiumAdminView({Key? key}) : super(key: key);

  @override
  State<PremiumAdminView> createState() => _PremiumAdminViewState();
}

class _PremiumAdminViewState extends State<PremiumAdminView> {
  bool _isLoading = true;
  bool _tienePremium = false;
  List<Map<String, dynamic>> _trabajos = [];
  String? _emailContratista;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await StorageService.getUser();
      final email = user?['email']?.toString();

      if (email == null) {
        if (mounted) {
          CustomNotification.showError(
            context,
            'No se encontró la sesión del contratista.',
          );
        }
        return;
      }

      _emailContratista = email;

      // Verificar premium
      final premiumResult = await ApiService.verificarPremium(email);
      final tienePremium = premiumResult['tienePremium'] == true;

      if (tienePremium) {
        // Cargar trabajos
        final trabajosResult = await ApiService.obtenerTrabajosAdministracion(email);
        if (trabajosResult['success'] == true) {
          setState(() {
            _trabajos = List<Map<String, dynamic>>.from(trabajosResult['trabajos'] ?? []);
          });
        }
      }

      setState(() {
        _tienePremium = tienePremium;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error al cargar datos: $e',
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNav(
        role: 'contratista',
        currentIndex: 2,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tienePremium
                ? _buildVistaPremium()
                : _buildVistaSinPremium(),
      ),
    );
  }

  Widget _buildVistaSinPremium() {
    return Column(
      children: [
        const HeaderBar(tipoUsuario: 'contratista'),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 25,
            tablet: 30,
            desktop: 40,
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(
                Responsive.getResponsiveSpacing(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 70,
                      tablet: 75,
                      desktop: 80,
                    ),
                    color: Colors.grey[400],
                  ),
                  SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 18,
                      tablet: 21,
                      desktop: 24,
                    ),
                  ),
                  Text(
                    'Funcionalidad Premium',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 22,
                        tablet: 23,
                        desktop: 24,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                    'Necesitas una suscripción premium para acceder a las herramientas de administración avanzadas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 25,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Navegar al perfil y abrir modal de planes
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileView(abrirPlanesPremium: true),
                        ),
                      );
                      
                      // Recargar datos si se activó premium
                      if (result == true || mounted) {
                        _cargarDatos();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F4E79),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 25,
                          tablet: 28,
                          desktop: 32,
                        ),
                        vertical: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver Planes Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVistaPremium() {
    return Column(
      children: [
        const HeaderBar(tipoUsuario: 'contratista'),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 10,
            tablet: 12,
            desktop: 15,
          ),
        ),
        Divider(
          color: Colors.black26,
          thickness: 1,
          indent: Responsive.getHorizontalPadding(context),
          endIndent: Responsive.getHorizontalPadding(context),
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 15,
            tablet: 18,
            desktop: 20,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getHorizontalPadding(context),
          ),
          child: Text(
            'Administración Premium',
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
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 6,
            tablet: 7,
            desktop: 8,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getHorizontalPadding(context),
          ),
          child: Text(
            'Gestiona tus trabajos de largo plazo',
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 13.5,
                desktop: 14,
              ),
              color: Colors.grey[600],
            ),
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
        Expanded(
          child: _trabajos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey[400],
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
                        'No tienes trabajos activos',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 17,
                            desktop: 18,
                          ),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getHorizontalPadding(context),
                      vertical: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 8,
                        tablet: 9,
                        desktop: 10,
                      ),
                    ),
                    itemCount: _trabajos.length,
                    itemBuilder: (context, index) {
                      return _buildTrabajoCard(_trabajos[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTrabajoCard(Map<String, dynamic> trabajo) {
    final rawId = trabajo['id_trabajo_largo'];
    final idTrabajo = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final titulo = trabajo['titulo']?.toString() ?? 'Sin título';
    final descripcion = trabajo['descripcion']?.toString() ?? '';
    final presupuesto = trabajo['presupuesto'];
    final monedaPresupuesto = trabajo['moneda_presupuesto']?.toString() ?? 'MXN';
    final fechaInicio = trabajo['fecha_inicio']?.toString();
    final fechaFin = trabajo['fecha_fin']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F4E79),
                    ),
                  ),
                ),
                if (presupuesto != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Presupuesto: \$${FormatService.formatPresupuesto(presupuesto)} $monedaPresupuesto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            if (descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (fechaInicio != null && fechaFin != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${FormatService.formatDateStringForDisplay(fechaInicio)} - ${FormatService.formatDateStringForDisplay(fechaFin)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.attach_money,
                  label: presupuesto == null ? 'Agregar Presupuesto' : 'Editar Presupuesto',
                  color: Colors.green,
                  onTap: () => _mostrarModalPresupuesto(idTrabajo, presupuesto),
                ),
                _buildActionButton(
                  icon: Icons.people_outline,
                  label: 'Ver Trabajadores',
                  color: Colors.blue,
                  onTap: () => _mostrarTrabajadores(idTrabajo),
                ),
                _buildActionButton(
                  icon: Icons.access_time,
                  label: 'Registrar Horas',
                  color: Colors.orange,
                  onTap: () => _mostrarModalHoras(idTrabajo),
                ),
                _buildActionButton(
                  icon: Icons.attach_money,
                  label: 'Gastos Extras',
                  color: Colors.red,
                  onTap: () => _mostrarModalGastosExtras(idTrabajo),
                ),
                _buildActionButton(
                  icon: Icons.description,
                  label: 'Ver Nómina',
                  color: Colors.purple,
                  onTap: () => _mostrarModalNomina(idTrabajo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _mostrarModalPresupuesto(int idTrabajo, dynamic presupuestoActual) {
    PremiumModals.mostrarModalPresupuesto(
      context,
      idTrabajo: idTrabajo,
      emailContratista: _emailContratista!,
      presupuestoActual: presupuestoActual,
      onGuardado: () {
        _cargarDatos();
      },
    );
  }

  void _mostrarTrabajadores(int idTrabajo) {
    PremiumModals.mostrarModalTrabajadores(
      context,
      idTrabajo: idTrabajo,
      emailContratista: _emailContratista!,
    );
  }

  void _mostrarModalHoras(int idTrabajo) {
    PremiumModals.mostrarModalHoras(
      context,
      idTrabajo: idTrabajo,
      emailContratista: _emailContratista!,
    );
  }

  void _mostrarModalNomina(int idTrabajo) {
    PremiumModals.mostrarModalNomina(
      context,
      idTrabajo: idTrabajo,
      emailContratista: _emailContratista!,
    );
  }

  void _mostrarModalGastosExtras(int idTrabajo) {
    PremiumModals.mostrarModalGastosExtras(
      context,
      idTrabajo: idTrabajo,
      emailContratista: _emailContratista!,
      onGuardado: () {
        // Recargar datos si es necesario
      },
    );
  }
}

