import express from 'express';
import {
  aplicarATrabajo,
  obtenerSolicitudPendiente,
  obtenerNumeroSolicitudesActivas,
  obtenerSolicitudesActivasTrabajador,
} from '../controllers/solicitudesController.js';

const router = express.Router();

router.post('/aplicar', aplicarATrabajo);
router.get('/pendiente', obtenerSolicitudPendiente);
router.get('/numero-activas', obtenerNumeroSolicitudesActivas);
router.get('/activas', obtenerSolicitudesActivasTrabajador);

export default router;


