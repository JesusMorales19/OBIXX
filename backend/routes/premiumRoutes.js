import express from 'express';
import {
  verificarPremium,
  activarSuscripcion,
  cancelarSuscripcion,
  obtenerTrabajosAdministracion,
  registrarPresupuesto,
  registrarHoras,
  configurarSueldo,
  obtenerTrabajadoresTrabajo,
  generarNomina,
  reiniciarHorasTrabajadores,
  registrarGastoExtra,
  obtenerGastosExtras,
} from '../controllers/premiumController.js';

const router = express.Router();

router.get('/verificar', verificarPremium);
router.post('/activar', activarSuscripcion);
router.post('/cancelar', cancelarSuscripcion);
router.get('/trabajos', obtenerTrabajosAdministracion);
router.post('/presupuesto', registrarPresupuesto);
router.post('/horas', registrarHoras);
router.post('/sueldo', configurarSueldo);
router.get('/trabajadores', obtenerTrabajadoresTrabajo);
router.post('/nomina', generarNomina);
router.post('/reiniciar-horas', reiniciarHorasTrabajadores);
router.post('/gastos-extras', registrarGastoExtra);
router.get('/gastos-extras', obtenerGastosExtras);

export default router;

