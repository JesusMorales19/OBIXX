import express from 'express';
import { 
  actualizarUbicacionContratista, 
  actualizarUbicacionTrabajador,
  buscarTrabajadoresCercanos,
  buscarTrabajadoresPorCategoria,
  buscarContratistasCercanos
} from '../controllers/ubicacionController.js';

const router = express.Router();

// Rutas para actualizar ubicación
router.put('/contratista', actualizarUbicacionContratista);
router.put('/trabajador', actualizarUbicacionTrabajador);

// Rutas para buscar cercanos
router.get('/trabajadores-cercanos', buscarTrabajadoresCercanos);
router.get('/trabajadores-por-categoria', buscarTrabajadoresPorCategoria);
router.get('/contratistas-cercanos', buscarContratistasCercanos);

export default router;

