import 'package:flutter/material.dart';

/// Widget reutilizable para dropdowns con estilo consistente
class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T)? itemBuilder;
  final ValueChanged<T?> onChanged;
  final Color? iconColor;
  final Color? borderColor;
  final String? Function(T?)? validator;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
    this.iconColor,
    this.borderColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? Colors.blueAccent;
    final defaultBorderColor = borderColor ?? Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: defaultIconColor),
          labelText: label,
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
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemBuilder?.call(item) ?? item.toString(),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

