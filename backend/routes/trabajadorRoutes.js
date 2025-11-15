import express from 'express';
import {
  obtenerPerfilTrabajador,
  actualizarPerfilTrabajador,
} from '../controllers/trabajadorController.js';

const router = express.Router();

router.get('/perfil', obtenerPerfilTrabajador);
router.put('/perfil', actualizarPerfilTrabajador);

export default router;

