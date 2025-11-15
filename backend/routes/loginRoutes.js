import express from 'express';
import { login, verifyToken } from '../controllers/loginController.js';

const router = express.Router();

// Ruta para login
router.post('/login', login);

// Ruta para verificar token
router.get('/verify', verifyToken);

export default router;

