import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o especialidad...',
          hintStyle: const TextStyle(
            color: Color(0xFF1F4E79),
            fontWeight: FontWeight.bold,
          ),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF1F4E79), size: 30),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 22, horizontal: 15),
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
