import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;

  const CustomSearchBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getHorizontalPadding(context),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o especialidad...',
          hintStyle: TextStyle(
            color: const Color(0xFF1F4E79),
            fontWeight: FontWeight.bold,
            fontSize: Responsive.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFF1F4E79),
            size: Responsive.getResponsiveFontSize(
              context,
              mobile: 26,
              tablet: 28,
              desktop: 30,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: Responsive.getResponsiveSpacing(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
            horizontal: Responsive.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 15,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
              color: Color(0xFF1F4E79),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
              color: Color(0xFF1F4E79),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
