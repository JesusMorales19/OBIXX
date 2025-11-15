import 'package:flutter/material.dart';
import 'presupuesto_modal.dart';
import 'trabajadores_modal.dart';
import 'horas_modal.dart';
import 'nomina_modal.dart';
import 'gastos_extras_modal.dart';

/// Clase principal que exporta todos los modales premium
/// Mantiene la misma interfaz pública para no romper código existente
class PremiumModals {

  // MODAL: REGISTRAR/EDITAR PRESUPUESTO

  static void mostrarModalPresupuesto(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
    dynamic presupuestoActual,
    required VoidCallback onGuardado,
  }) {
    PresupuestoModal.mostrar(
      context,
      idTrabajo: idTrabajo,
      emailContratista: emailContratista,
      presupuestoActual: presupuestoActual,
      onGuardado: onGuardado,
    );
  }

  // MODAL: VER TRABAJADORES Y CONFIGURAR SUELDO

  static void mostrarModalTrabajadores(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
  }) {
    TrabajadoresModal.mostrar(
      context,
      idTrabajo: idTrabajo,
      emailContratista: emailContratista,
    );
  }

  // MODAL: REGISTRAR HORAS

  static void mostrarModalHoras(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
  }) {
    HorasModal.mostrar(
      context,
      idTrabajo: idTrabajo,
      emailContratista: emailContratista,
    );
  }

  // MODAL: GENERAR/DESCARGAR NÓMINA

  static void mostrarModalNomina(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
  }) {
    NominaModal.mostrar(
      context,
      idTrabajo: idTrabajo,
      emailContratista: emailContratista,
    );
  }


  // MODAL: REGISTRAR GASTOS EXTRAS

  static void mostrarModalGastosExtras(
    BuildContext context, {
    required int idTrabajo,
    required String emailContratista,
    VoidCallback? onGuardado,
  }) {
    GastosExtrasModal.mostrar(
      context,
      idTrabajo: idTrabajo,
      emailContratista: emailContratista,
      onGuardado: onGuardado,
    );
  }
}
