import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

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
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getHorizontalPadding(context),
      ),
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
                hintStyle: TextStyle(
                  color: const Color(0xFF1F4E79),
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 12.5,
                    desktop: 13,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFF1F4E79),
                  size: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 35,
                    tablet: 37,
                    desktop: 40,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 15,
                    tablet: 18,
                    desktop: 20,
                  ),
                  horizontal: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 9,
                    desktop: 10,
                  ),
                ),
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
          SizedBox(
            width: Responsive.getResponsiveSpacing(
              context,
              mobile: 6,
              tablet: 7,
              desktop: 8,
            ),
          ),
          // ---------- BOTÓN DESPLEGABLE ----------
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 9,
                  desktop: 10,
                ),
                vertical: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 9,
                  desktop: 10,
                ),
              ),
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
