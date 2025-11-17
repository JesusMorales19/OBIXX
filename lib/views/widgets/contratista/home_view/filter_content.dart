import 'package:flutter/material.dart';
import '../../../../services/format_service.dart';
import '../../../../core/utils/responsive.dart';

class FilterContent extends StatelessWidget {
  final String selectedFilter;
  final double minEdad;
  final double maxEdad;
  final double experiencia;
  final double rating;
  final TextEditingController experienciaController;
  final FocusNode experienciaFocusNode;
  final ValueChanged<RangeValues> onChangedEdad;
  final ValueChanged<double> onChangedExperiencia;
  final ValueChanged<double> onChangedRating;

  const FilterContent({
    super.key,
    required this.selectedFilter,
    required this.minEdad,
    required this.maxEdad,
    required this.experiencia,
    required this.rating,
    required this.experienciaController,
    required this.experienciaFocusNode,
    required this.onChangedEdad,
    required this.onChangedExperiencia,
    required this.onChangedRating,
  });

  @override
  Widget build(BuildContext context) {
    if(selectedFilter=='Edad'){
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selecciona un rango de edad:",
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            values: RangeValues(minEdad,maxEdad),
            min:18,
            max:60,
            divisions:42,
            labels: RangeLabels('${minEdad.round()}','${maxEdad.round()}'),
            activeColor: Colors.blueAccent,
            onChanged: onChangedEdad,
          ),
        ],
      );
    } else if(selectedFilter=='Experiencia'){
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Años mínimos de experiencia:",
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: Responsive.getResponsiveSpacing(
              context,
              mobile: 6,
              tablet: 7,
              desktop: 8,
            ),
          ),
          TextField(
            controller: experienciaController,
            focusNode: experienciaFocusNode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Ejemplo: 3",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (val) => onChangedExperiencia(FormatService.parseDouble(val)),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Valoración mínima (0.0 - 5.0):",
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: rating,
            min:0,
            max:5,
            divisions:50,
            label: rating.toStringAsFixed(1),
            activeColor: Colors.blueAccent,
            onChanged: onChangedRating,
          ),
          Center(
            child: Text(
              "${rating.toStringAsFixed(1)} ⭐",
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}