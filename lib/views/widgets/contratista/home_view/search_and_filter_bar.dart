import 'package:flutter/material.dart';

class SearchAndFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final ValueChanged<String>? onSearchChanged;

  const SearchAndFilterBar({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    this.onFilterChanged,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // ---------- BUSCADOR ----------
          Expanded(
            flex: 2,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoría...',
                hintStyle: const TextStyle(
                  color: Color(0xFF1F4E79),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF1F4E79), size: 40),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: Color(0xFF1F4E79), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: Color(0xFF1F4E79), width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ---------- BOTÓN DESPLEGABLE ----------
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF1F4E79), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1F4E79)),
                  items: const <String>['Todas', 'Favoritos'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF1F4E79),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null && onFilterChanged != null) {
                      onFilterChanged!(newValue);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
