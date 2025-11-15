import 'package:flutter/material.dart';

class SearchAndFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;
  final ValueChanged<String>? onSearchChanged;

  const SearchAndFilterBar({
    super.key,
    required this.searchController,
    this.selectedFilter,
    this.onFilterChanged,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                hintStyle: const TextStyle(color: Color(0xFF1F4E79), fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1F4E79)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1F4E79), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1F4E79), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1F4E79), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1F4E79), width: 2),
                ),
              ),
              hint: const Text(
                'Todos',
                style: TextStyle(color: Color(0xFF1F4E79), fontWeight: FontWeight.bold),
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Todos',
                      style: TextStyle(color: Color(0xFF1F4E79))),
                ),
                DropdownMenuItem(
                  value: 'largo',
                  child: Text('Largo Plazo',
                      style: TextStyle(color: Color(0xFF1F4E79))),
                ),
                DropdownMenuItem(
                  value: 'corto',
                  child: Text('Corto plazo',
                      style: TextStyle(color: Color(0xFF1F4E79))),
                ),
                DropdownMenuItem(
                  value: 'en_proceso',
                  child: Text('En proceso',
                      style: TextStyle(color: Color(0xFF1F4E79))),
                ),
                DropdownMenuItem(
                  value: 'terminado',
                  child: Text('Terminado',
                      style: TextStyle(color: Color(0xFF1F4E79))),
                ),
              ],
              onChanged: onFilterChanged,
            ),
          ),
        ],
      ),
    );
  }
}
