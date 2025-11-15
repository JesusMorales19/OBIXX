import 'package:flutter/material.dart';

class FilterChoiceChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;
  const FilterChoiceChips({super.key, required this.selectedFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(label: const Text('Edad'), selected: selectedFilter=='Edad', onSelected: (_) => onChanged('Edad')),
        ChoiceChip(label: const Text('Experiencia'), selected: selectedFilter=='Experiencia', onSelected: (_) => onChanged('Experiencia')),
        ChoiceChip(label: const Text('Valoración'), selected: selectedFilter=='Valoración', onSelected: (_) => onChanged('Valoración')),
      ],
    );
  }
}