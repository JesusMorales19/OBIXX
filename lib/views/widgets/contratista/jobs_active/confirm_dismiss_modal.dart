import 'package:flutter/material.dart';
import 'package:integradora/views/widgets/contratista/jobs_active/rate_worker_modal.dart';
import '../../../../core/utils/responsive.dart';

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
        insetPadding: EdgeInsets.symmetric(
          horizontal: Responsive.getResponsiveSpacing(
            context,
            mobile: 20,
            tablet: 25,
            desktop: 30,
          ),
          vertical: Responsive.getResponsiveSpacing(
            context,
            mobile: 120,
            tablet: 160,
            desktop: 200,
          ),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(
            Responsive.getResponsiveSpacing(
              context,
              mobile: 15,
              tablet: 18,
              desktop: 20,
            ),
          ),
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
              Icon(
                Icons.warning_amber_rounded,
                size: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 50,
                  tablet: 55,
                  desktop: 60,
                ),
                color: Colors.orange,
              ),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 15,
                ),
              ),
              Text(
                "¿Estás seguro que quieres desvincular a $nombre?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 17,
                    desktop: 18,
                  ),
                  color: Colors.black,
                  fontWeight: FontWeight.normal
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 15,
                          tablet: 18,
                          desktop: 20,
                        ),
                        vertical: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 10,
                          tablet: 11,
                          desktop: 12,
                        ),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.9),
                      side: const BorderSide(color: Color(0xFF1F4E79)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(
                        color: const Color(0xFF1F4E79),
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 25,
                        ),
                        vertical: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 10,
                          tablet: 11,
                          desktop: 12,
                        ),
                      ),
                      backgroundColor: const Color(0xFF1F4E79),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Aceptar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
              )
            ],
          ),
        ),
      );
    },
  );
}
