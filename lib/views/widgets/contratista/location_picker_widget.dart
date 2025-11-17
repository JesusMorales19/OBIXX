import 'package:flutter/material.dart';
import 'package:integradora/services/location_service.dart';
import '../custom_notification.dart';
import '../../../../core/utils/responsive.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(double? lat, double? lon, String? direccion) onLocationSelected;
  final double? initialLat;
  final double? initialLon;

  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLat,
    this.initialLon,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  double? _latitud;
  double? _longitud;
  String? _direccion;
  bool _isLoading = false;
  final TextEditingController _direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _latitud = widget.initialLat;
    _longitud = widget.initialLon;
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await LocationService.obtenerUbicacionActual();
      
      if (position != null) {
        setState(() {
          _latitud = position.latitude;
          _longitud = position.longitude;
          _isLoading = false;
        });

        widget.onLocationSelected(_latitud, _longitud, _direccion);
        
        if (mounted) {
          CustomNotification.showSuccess(
            context,
            '✅ Ubicación actual obtenida',
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          CustomNotification.showError(
            context,
            'No se pudo obtener la ubicación',
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
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 15,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1F4E79), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFF1F4E79),
                size: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
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
                'Ubicación del Trabajo',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F4E79),
                ),
              ),
            ],
          ),
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 15,
            ),
          ),

          // Campo de dirección (opcional)
          TextField(
            controller: _direccionController,
            decoration: InputDecoration(
              hintText: 'Dirección (opcional)',
              prefixIcon: const Icon(Icons.home),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              _direccion = value.trim().isNotEmpty ? value.trim() : null;
              // Actualizar siempre, incluso si solo hay dirección sin coordenadas
              widget.onLocationSelected(_latitud, _longitud, _direccion);
            },
          ),
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 15,
            ),
          ),

          // Botón para obtener ubicación actual
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _obtenerUbicacionActual,
              icon: _isLoading
                  ? SizedBox(
                      width: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 18,
                        tablet: 19,
                        desktop: 20,
                      ),
                      height: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 18,
                        tablet: 19,
                        desktop: 20,
                      ),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.my_location,
                      size: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 18,
                        tablet: 19,
                        desktop: 20,
                      ),
                    ),
              label: Text(
                _isLoading 
                    ? 'Obteniendo ubicación...' 
                    : 'Usar Ubicación Actual',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F4E79),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 11,
                    desktop: 12,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Mostrar coordenadas si están disponibles
          if (_latitud != null && _longitud != null) ...[
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 12,
                tablet: 13,
                desktop: 15,
              ),
            ),
            Container(
              padding: EdgeInsets.all(
                Responsive.getResponsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 9,
                  desktop: 10,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                      SizedBox(
                        width: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 4,
                          tablet: 4.5,
                          desktop: 5,
                        ),
                      ),
                      Text(
                        'Ubicación Seleccionada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
                  SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 6,
                      tablet: 7,
                      desktop: 8,
                    ),
                  ),
                  Text(
                    'Latitud: ${_latitud!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 11,
                        tablet: 11.5,
                        desktop: 12,
                      ),
                    ),
                  ),
                  Text(
                    'Longitud: ${_longitud!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 11,
                        tablet: 11.5,
                        desktop: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 8,
              tablet: 9,
              desktop: 10,
            ),
          ),
          Text(
            'Nota: Puedes usar tu ubicación actual si estás en el lugar del trabajo, o agregar la dirección manualmente.',
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 11.5,
                desktop: 12,
              ),
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

