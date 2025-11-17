import 'package:flutter/material.dart';
import 'filter_content.dart';
import 'filter_choice_chips.dart';
import '../../../../core/utils/responsive.dart';

class FilterModal extends StatefulWidget {
  final double? minEdad;
  final double? maxEdad;
  final double? minExperiencia;
  final double? minRating;
  final TextEditingController experienciaController;
  final FocusNode experienciaFocusNode;
  final Function(RangeValues edad, double exp, double rating) onApply;
  final VoidCallback onClear;

  const FilterModal({
    super.key,
    required this.minEdad,
    required this.maxEdad,
    required this.minExperiencia,
    required this.minRating,
    required this.experienciaController,
    required this.experienciaFocusNode,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String selectedFilter = 'Edad';
  late double tempMinEdad;
  late double tempMaxEdad;
  late double tempExperiencia;
  late double tempRating;

  @override
  void initState() {
    super.initState();
    tempMinEdad = widget.minEdad ?? 18;
    tempMaxEdad = widget.maxEdad ?? 60;
    tempExperiencia = widget.minExperiencia ?? 0;
    tempRating = widget.minRating ?? 0.0;
    widget.experienciaController.text = tempExperiencia > 0 ? tempExperiencia.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            left: Responsive.getHorizontalPadding(context),
            right: Responsive.getHorizontalPadding(context),
            top: Responsive.getResponsiveSpacing(
              context,
              mobile: 15,
              tablet: 18,
              desktop: 20,
            ),
            bottom: MediaQuery.of(context).viewInsets.bottom + Responsive.getResponsiveSpacing(
              context,
              mobile: 15,
              tablet: 18,
              desktop: 20,
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 4,
                      tablet: 4.5,
                      desktop: 5,
                    ),
                    width: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 45,
                      tablet: 47,
                      desktop: 50,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(
                          Radius.circular(Responsive.getResponsiveSpacing(
                            context,
                            mobile: 4,
                            tablet: 4.5,
                            desktop: 5,
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 9,
                    desktop: 10,
                  ),
                ),
                Text(
                  "Filtrar empleados",
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 19,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 15,
                  ),
                ),
                FilterChoiceChips(selectedFilter: selectedFilter, onChanged: (val) {
                  setState(() => selectedFilter = val);
                  if (val == 'Experiencia') {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!widget.experienciaFocusNode.hasFocus) {
                        FocusScope.of(context).requestFocus(widget.experienciaFocusNode);
                      }
                    });
                  }
                }),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 25,
                  ),
                ),
                FilterContent(
                  selectedFilter: selectedFilter,
                  minEdad: tempMinEdad,
                  maxEdad: tempMaxEdad,
                  experiencia: tempExperiencia,
                  rating: tempRating,
                  experienciaController: widget.experienciaController,
                  experienciaFocusNode: widget.experienciaFocusNode,
                  onChangedEdad: (v) => setState(() { tempMinEdad = v.start; tempMaxEdad = v.end; }),
                  onChangedExperiencia: (v) => setState(() => tempExperiencia = v),
                  onChangedRating: (v) => setState(() => tempRating = v),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 25,
                    tablet: 27,
                    desktop: 30,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () { widget.onClear(); Navigator.pop(context); },
                      child: Text(
                        "Limpiar",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () { widget.onApply(RangeValues(tempMinEdad,tempMaxEdad), tempExperiencia, tempRating); Navigator.pop(context); },
                      icon: Icon(
                        Icons.check,
                        size: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 19,
                          desktop: 20,
                        ),
                      ),
                      label: Text(
                        "Aplicar filtro",
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}