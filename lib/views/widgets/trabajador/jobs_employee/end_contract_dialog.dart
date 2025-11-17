import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

class EndContractDialog {
  static void show(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: true, // permite cerrar tocando fuera del modal
      builder: (BuildContext context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.all(
                Responsive.getResponsiveSpacing(
                  context,
                  mobile: 15,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Ícono de advertencia
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveSpacing(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 45,
                        tablet: 47,
                        desktop: 50,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),

                  // 🔹 Título
                  Text(
                    "¿Estás seguro?",
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 21,
                        desktop: 22,
                      ),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F4E79),
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

                  // 🔹 Descripción
                  Text(
                    "¿Deseas terminar este contrato? Esta acción no se puede deshacer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 15,
                      ),
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 25,
                    ),
                  ),

                  // 🔹 Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón cancelar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                            vertical: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 9,
                              desktop: 10,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancelar",
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

                      // Botón confirmar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                            vertical: Responsive.getResponsiveSpacing(
                              context,
                              mobile: 8,
                              tablet: 9,
                              desktop: 10,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        child: Text(
                          "Sí, terminar",
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
