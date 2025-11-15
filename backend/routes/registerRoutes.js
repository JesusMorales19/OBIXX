import express from 'express';
import { registerContratista, registerTrabajador } from '../controllers/registerController.js';

const router = express.Router();

// Ruta para registrar contratista
router.post('/contratista', registerContratista);

// Ruta para registrar trabajador
router.post('/trabajador', registerTrabajador);

export default router;



