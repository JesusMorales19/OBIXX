import 'package:flutter/material.dart';
import 'custom_notification.dart';
import '../../services/validation_service.dart';
import '../../core/utils/responsive.dart';

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
              padding: EdgeInsets.all(
                Responsive.getResponsiveSpacing(
                  context,
                  mobile: 18,
                  tablet: 21,
                  desktop: 25,
                ),
              ),
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
                      Text(
                        'Cambiar Contraseña',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F4E79),
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
                      TextFormField(
                        controller: currentController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          hintText: 'Ingrese su contraseña actual',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_person_outlined,
                            size: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 21,
                              desktop: 22,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? Icons.visibility_off : Icons.visibility,
                              size: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 21,
                                desktop: 22,
                              ),
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
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 15,
                        ),
                      ),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          hintText: 'Ingrese nueva contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            size: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 21,
                              desktop: 22,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off : Icons.visibility,
                              size: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 21,
                                desktop: 22,
                              ),
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
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 15,
                        ),
                      ),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          hintText: 'Repita la contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            size: Responsive.getResponsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 21,
                              desktop: 22,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              size: Responsive.getResponsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 21,
                                desktop: 22,
                              ),
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
                      SizedBox(
                        height: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 25,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.getResponsiveSpacing(
                                  context,
                                  mobile: 25,
                                  tablet: 27,
                                  desktop: 30,
                                ),
                                vertical: Responsive.getResponsiveSpacing(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 15,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
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
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.getResponsiveSpacing(
                                  context,
                                  mobile: 25,
                                  tablet: 27,
                                  desktop: 30,
                                ),
                                vertical: Responsive.getResponsiveSpacing(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 15,
                                ),
                              ),
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
                            child: Text(
                              'Guardar',
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
