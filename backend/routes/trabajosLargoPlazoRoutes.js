import express from 'express';
import {
  registrarTrabajoLargoPlazo,
  obtenerTrabajosPorContratista,
  buscarTrabajosCercanos,
  actualizarEstadoTrabajo,
} from '../controllers/trabajosLargoPlazoController.js';

const router = express.Router();

// Registrar nuevo trabajo de largo plazo
router.post('/registrar', registrarTrabajoLargoPlazo);

// Obtener trabajos de un contratista
router.get('/contratista', obtenerTrabajosPorContratista);

// Buscar trabajos cercanos (para trabajadores)
router.get('/cercanos', buscarTrabajosCercanos);

// Actualizar estado de un trabajo
router.put('/:idTrabajo/estado', actualizarEstadoTrabajo);

export default router;

