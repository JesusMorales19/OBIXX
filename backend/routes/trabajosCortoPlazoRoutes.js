import express from 'express';

import {
  registrarTrabajoCortoPlazo,
  obtenerTrabajosCortoPorContratista,
  buscarTrabajosCortoCercanos,
} from '../controllers/trabajosCortoPlazoController.js';

const router = express.Router();

router.post('/registrar', registrarTrabajoCortoPlazo);
router.get('/contratista', obtenerTrabajosCortoPorContratista);
router.get('/cercanos', buscarTrabajosCortoCercanos);

export default router;


