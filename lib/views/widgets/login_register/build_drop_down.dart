import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  final double width; // 🔹 ancho uniforme
  final ValueChanged<String>? onChanged; // 🔹 callback para cambios

  const CustomDropdown({
    super.key,
    required this.label,
    required this.items,
    this.width = 320,
    this.onChanged,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width, // 🔹 mismo ancho que los InputFields
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(widget.label),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF1F0F0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
          ),
        ),
        items: widget.items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          setState(() => selectedValue = value);
          if (value != null && widget.onChanged != null) {
            widget.onChanged!(value);
          }
        },
      ),
    );
  }
}
