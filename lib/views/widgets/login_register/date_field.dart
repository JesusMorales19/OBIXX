import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final double width;
  final String? errorText;
  final VoidCallback? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  const DateField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.width = 320,
    this.errorText,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialDate,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFE67E22),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      // Formatear la fecha como DD/MM/AAAA
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      controller.text = formattedDate;
      if (onChanged != null) {
        onChanged!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width,
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: () => _selectDate(context),
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, color: Color(0xFFE67E22)),
                onPressed: () => _selectDate(context),
              ),
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

