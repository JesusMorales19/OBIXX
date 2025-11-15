import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import 'sueldo_modal.dart';

class TrabajadoresModal {
  static void mostrar(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.obtenerTrabajadoresTrabajo(
            idTrabajoLargo: idTrabajo,
            emailContratista: emailContratista,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || snapshot.data?['success'] != true) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Trabajadores',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar trabajadores',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final trabajadores = List<Map<String, dynamic>>.from(
              snapshot.data!['trabajadores'] ?? [],
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trabajadores',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                ),
                if (trabajadores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No hay trabajadores asignados'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: trabajadores.length,
                      itemBuilder: (context, index) {
                        final trabajador = trabajadores[index];
                        return _buildTrabajadorCard(
                          context,
                          trabajador,
                          idTrabajo,
                          emailContratista,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildTrabajadorCard(
    BuildContext context,
    Map<String, dynamic> trabajador,
    int idTrabajo,
    String emailContratista,
  ) {
    final nombre = '${trabajador['nombre']} ${trabajador['apellido']}';
    final tieneSueldo = trabajador['monto_periodo'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (tieneSueldo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sueldo configurado',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              SueldoModal.mostrar(
                context,
                trabajador: trabajador,
                idTrabajo: idTrabajo,
                emailContratista: emailContratista,
              );
            },
            icon: const Icon(Icons.payment, size: 18, color: Colors.white),
            label: Text(
              tieneSueldo ? 'Editar Sueldo' : 'Configurar Sueldo',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

