import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Título
                  const Text(
                    "¿Estás seguro?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F4E79),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔹 Descripción
                  const Text(
                    "¿Deseas terminar este contrato? Esta acción no se puede deshacer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),

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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),

                      // Botón confirmar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        child: const Text("Sí, terminar"),
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
