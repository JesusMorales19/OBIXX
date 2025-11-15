import express from 'express';
import {
  asignarTrabajo,
  cancelarAsignacion,
  obtenerAsignacionesContratista,
  obtenerTrabajadoresPorTrabajo,
  finalizarTrabajo,
  obtenerTrabajoActualTrabajador,
} from '../controllers/asignacionesController.js';

const router = express.Router();

router.post('/asignar', asignarTrabajo);
router.post('/cancelar', cancelarAsignacion);
router.get('/contratista', obtenerAsignacionesContratista);
router.get('/trabajadores', obtenerTrabajadoresPorTrabajo);
router.get('/trabajador/actual', obtenerTrabajoActualTrabajador);
router.post('/finalizar', finalizarTrabajo);

export default router;
