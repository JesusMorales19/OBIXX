import express from 'express';
import {
  registrarCalificacion,
  obtenerCalificacionesTrabajador,
} from '../controllers/calificacionesController.js';

const router = express.Router();

router.post('/registrar', registrarCalificacion);
router.get('/trabajador', obtenerCalificacionesTrabajador);

export default router;

