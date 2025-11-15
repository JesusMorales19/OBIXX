import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget reutilizable para campos de texto con estilo consistente
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Color? iconColor;
  final Color? borderColor;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.iconColor,
    this.borderColor,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? Colors.blueAccent;
    final defaultBorderColor = borderColor ?? Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: defaultIconColor),
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: defaultBorderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: defaultBorderColor, width: 2),
          ),
        ),
        validator: validator ??
            (keyboardType == TextInputType.number
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (keyboardType == TextInputType.number) {
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Ingrese un número válido';
                      }
                    }
                    return null;
                  }
                : (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  }),
        onChanged: onChanged,
      ),
    );
  }
}

