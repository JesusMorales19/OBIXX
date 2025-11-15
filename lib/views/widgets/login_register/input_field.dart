import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? toggleVisibility;
  final double width; // 🔹 ancho uniforme
  final String? errorText; // 🔹 mensaje de error
  final TextInputType? keyboardType; // 🔹 tipo de teclado
  final ValueChanged<String>? onChanged; // 🔹 callback para cambios

  const InputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.toggleVisibility,
    this.width = 320, // 🔹 valor por defecto
    this.errorText,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width, // 🔹 aplica ancho uniforme
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F0F0),
              prefixIcon: Icon(icon, color: const Color(0xFFE67E22)),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : const Color(0xFF2563EB),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : const Color(0xFF2563EB),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFFE67E22),
                      ),
                      onPressed: toggleVisibility,
                    )
                  : null,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
