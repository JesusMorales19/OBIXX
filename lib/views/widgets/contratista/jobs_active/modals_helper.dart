import 'package:flutter/material.dart';
import 'confirm_end_job_modal.dart';
import 'rate_employees_modal.dart';

void showEndJobFlow(
  BuildContext context, {
  required BuildContext parentContext,
  required List<Map<String, dynamic>> trabajadores,
  required String emailContratista,
  required String tipoTrabajo,
  required int idTrabajo,
  Future<void> Function()? onCompleted,
}) {
  showDialog(
    context: context,
    builder: (_) => ConfirmEndJobModal(
      onConfirm: () {
        Future.microtask(() {
          showDialog(
            context: parentContext,
            builder: (_) => RateEmployeesModal(
              parentContext: parentContext,
              trabajadores: trabajadores,
              emailContratista: emailContratista,
              tipoTrabajo: tipoTrabajo,
              idTrabajo: idTrabajo,
              onCompleted: onCompleted,
            ),
          );
        });
      },
    ),
  );
}
