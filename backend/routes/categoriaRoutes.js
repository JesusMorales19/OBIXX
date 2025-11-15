import express from 'express';
import { getCategorias } from '../controllers/categoriaController.js';

const router = express.Router();

// Ruta para obtener todas las categorías
router.get('/', getCategorias);

export default router;











