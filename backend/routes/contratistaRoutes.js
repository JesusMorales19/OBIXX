import express from 'express';
import {
  obtenerPerfilContratista,
  actualizarPerfilContratista,
} from '../controllers/contratistaController.js';

const router = express.Router();

router.get('/perfil', obtenerPerfilContratista);
router.put('/perfil', actualizarPerfilContratista);

export default router;
