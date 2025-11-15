import express from 'express';
import {
  registrarToken,
  eliminarToken,
  listarNotificaciones,
  marcarLeidas,
  eliminarNotificaciones,
  registrarInteresContratista,
  registrarCancelacionContratista,
} from '../controllers/notificacionesController.js';

const router = express.Router();

router.post('/token', registrarToken);
router.delete('/token', eliminarToken);
router.get('/', listarNotificaciones);
router.post('/marcar-leidas', marcarLeidas);
router.delete('/', eliminarNotificaciones);
router.post('/interes-contratista', registrarInteresContratista);
router.post('/cancelacion-contratista', registrarCancelacionContratista);

export default router;


