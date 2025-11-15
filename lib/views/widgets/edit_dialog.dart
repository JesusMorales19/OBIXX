import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditDialog {
  /// Muestra un modal moderno para editar un valor
  static Future<void> show(
    BuildContext context,
    String title,
    String currentValue,
    Future<bool> Function(String) onSave, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // Fondo transparente
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono decorativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Text(
                'Editar $title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1F4E79),
                ),
              ),
              const SizedBox(height: 12),

              // Campo de texto
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                textCapitalization: textCapitalization,
                decoration: InputDecoration(
                  hintText: 'Ingrese $title',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child:
                        const Text('Cancelar', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      elevation: 6,
                      shadowColor: Colors.blueAccent,
                    ),
                    onPressed: () async {
                      final nuevoValor = controller.text.trim();
                      final success = await onSave(nuevoValor);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child:
                        const Text('Guardar', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
