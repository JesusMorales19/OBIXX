import 'package:flutter/material.dart';
import 'custom_notification.dart';
import '../../services/validation_service.dart';

class ChangePasswordDialogModern {
  static void show(
    BuildContext context,
    Future<bool> Function(String currentPassword, String newPassword) onSave,
  ) {
    final TextEditingController currentController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          void toggleCurrent() => setState(() => obscureCurrent = !obscureCurrent);
          void toggleNew() => setState(() => obscureNew = !obscureNew);
          void toggleConfirm() =>
              setState(() => obscureConfirm = !obscureConfirm);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Cambiar Contraseña',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F4E79),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: currentController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          hintText: 'Ingrese su contraseña actual',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: const Icon(Icons.lock_person_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: toggleCurrent,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Debe ingresar su contraseña actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          hintText: 'Ingrese nueva contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: toggleNew,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña no puede estar vacía';
                          }
                          // Usar ValidationService para validación de contraseña
                          // Ajustado para mínimo 6 caracteres (en lugar de 8)
                          if (value.length < 6) {
                            return 'Debe tener al menos 6 caracteres';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Debe incluir al menos una mayúscula';
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'Debe incluir al menos una minúscula';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Debe incluir al menos un número';
                          }
                          return null;
                        }
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          hintText: 'Repita la contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: toggleConfirm,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Debe confirmar la contraseña';
                          }
                          if (value != passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;

                              final success = await onSave(
                                currentController.text,
                                passwordController.text,
                              );

                              if (success && context.mounted) {
                                Navigator.pop(context);
                                CustomNotification.showSuccess(
                                  context,
                                  'Contraseña cambiada con éxito',
                                );
                              }
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
