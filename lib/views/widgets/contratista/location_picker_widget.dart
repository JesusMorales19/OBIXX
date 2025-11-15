import 'package:flutter/material.dart';
import 'package:integradora/services/location_service.dart';
import '../custom_notification.dart';

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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1F4E79), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF1F4E79)),
              SizedBox(width: 8),
              Text(
                'Ubicación del Trabajo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F4E79),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

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
          const SizedBox(height: 15),

          // Botón para obtener ubicación actual
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _obtenerUbicacionActual,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isLoading 
                  ? 'Obteniendo ubicación...' 
                  : 'Usar Ubicación Actual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F4E79),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Mostrar coordenadas si están disponibles
          if (_latitud != null && _longitud != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Ubicación Seleccionada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitud: ${_latitud!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Longitud: ${_longitud!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Text(
            'Nota: Puedes usar tu ubicación actual si estás en el lugar del trabajo, o agregar la dirección manualmente.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

