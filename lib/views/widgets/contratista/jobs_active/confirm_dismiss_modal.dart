import 'package:flutter/material.dart';
import 'package:integradora/views/widgets/contratista/jobs_active/rate_worker_modal.dart';

void showConfirmarDespedirModal(
  BuildContext context, {
  required String nombre,
  required String emailContratista,
  required String emailTrabajador,
  required int idAsignacion,
  required BuildContext parentContext,
  Future<void> Function()? onCompleted,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 200),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 15),
              Text(
                "¿Estás seguro que quieres desvincular a $nombre?",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.normal
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.white.withOpacity(0.9),
                      side: const BorderSide(color: Color(0xFF1F4E79)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(
                        color: Color(0xFF1F4E79),
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra confirmación
                      Future.microtask(() {
                        showCalificarTrabajadorModal(
                          parentContext,
                          parentContext: parentContext,
                          nombre: nombre,
                          emailContratista: emailContratista,
                          emailTrabajador: emailTrabajador,
                          idAsignacion: idAsignacion,
                          onCompleted: onCompleted,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      backgroundColor: Color(0xFF1F4E79),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Aceptar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}
