import 'package:flutter/material.dart';
import 'filter_content.dart';
import 'filter_choice_chips.dart';

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
          padding: EdgeInsets.only(left: 20,right: 20,top: 20,bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SizedBox(height: 5, width: 50, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(5)))))),
                const SizedBox(height: 10),
                const Text("Filtrar empleados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
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
                const SizedBox(height: 25),
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
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () { widget.onClear(); Navigator.pop(context); }, child: const Text("Limpiar", style: TextStyle(color: Colors.red))),
                    ElevatedButton.icon(
                      onPressed: () { widget.onApply(RangeValues(tempMinEdad,tempMaxEdad), tempExperiencia, tempRating); Navigator.pop(context); },
                      icon: const Icon(Icons.check),
                      label: const Text("Aplicar filtro"),
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE67E22),foregroundColor: Colors.white,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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