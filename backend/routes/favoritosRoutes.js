import express from 'express';
import {
  agregarFavorito,
  quitarFavorito,
  verificarFavorito,
  listarFavoritos,
} from '../controllers/favoritosController.js';

const router = express.Router();

// Agregar trabajador a favoritos
router.post('/agregar', agregarFavorito);

// Quitar trabajador de favoritos
router.delete('/quitar', quitarFavorito);

// Verificar si un trabajador está en favoritos
router.get('/verificar', verificarFavorito);

// Listar todos los favoritos de un contratista
router.get('/listar', listarFavoritos);

export default router;

