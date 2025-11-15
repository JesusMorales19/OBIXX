import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { testConnection } from './config/db.js';
import registerRoutes from './routes/registerRoutes.js';
import categoriaRoutes from './routes/categoriaRoutes.js';
import loginRoutes from './routes/loginRoutes.js';
import ubicacionRoutes from './routes/ubicacionRoutes.js';
import favoritosRoutes from './routes/favoritosRoutes.js';
import trabajosLargoPlazoRoutes from './routes/trabajosLargoPlazoRoutes.js';
import trabajosCortoPlazoRoutes from './routes/trabajosCortoPlazoRoutes.js';
import contratistaRoutes from './routes/contratistaRoutes.js';
import asignacionesRoutes from './routes/asignacionesRoutes.js';
import calificacionesRoutes from './routes/calificacionesRoutes.js';
import trabajadorRoutes from './routes/trabajadorRoutes.js';
import notificacionesRoutes from './routes/notificacionesRoutes.js';
import solicitudesRoutes from './routes/solicitudesRoutes.js';
import premiumRoutes from './routes/premiumRoutes.js';
import { initializeFirebaseApp } from './services/firebaseService.js';

// Cargar variables de entorno
dotenv.config();
initializeFirebaseApp();

// Manejo de errores globales para evitar que el servidor se cierre
process.on('uncaughtException', (error) => {
  console.error('❌ Error no capturado:', error);
  console.error('Stack:', error.stack);
  // No cerrar el proceso, solo registrar el error
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Promesa rechazada no manejada:', reason);
  console.error('Promise:', promise);
  // No cerrar el proceso, solo registrar el error
});

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors({
  origin: '*', // Permitir todos los orígenes (en producción usar un origen específico)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
}));
// Aumentar el límite de tamaño del body para permitir imágenes en Base64
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Middleware para logging de peticiones
app.use((req, res, next) => {
  console.log(`📥 ${req.method} ${req.path} - ${new Date().toLocaleTimeString()}`);
  next();
});

// Ruta de prueba para verificar que el servidor está funcionando
app.get('/', (req, res) => {
  res.json({
    message: 'Servidor backend funcionando correctamente',
    database: process.env.DB_NAME || 'AppContractor',
    port: PORT,
  });
});

// Rutas
app.use('/api/register', registerRoutes);
app.use('/api/categorias', categoriaRoutes);
app.use('/api/auth', loginRoutes);
app.use('/api/ubicacion', ubicacionRoutes);
app.use('/api/favoritos', favoritosRoutes);
app.use('/api/trabajos-largo-plazo', trabajosLargoPlazoRoutes);
app.use('/api/trabajos-corto-plazo', trabajosCortoPlazoRoutes);
app.use('/api/contratistas', contratistaRoutes);
app.use('/api/asignaciones', asignacionesRoutes);
app.use('/api/trabajadores', trabajadorRoutes);
app.use('/api/calificaciones', calificacionesRoutes);
app.use('/api/notificaciones', notificacionesRoutes);
app.use('/api/solicitudes', solicitudesRoutes);
app.use('/api/premium', premiumRoutes);

// Ruta para verificar la conexión a la base de datos
app.get('/api/health', async (req, res) => {
  try {
    const isConnected = await testConnection();
    if (isConnected) {
      res.json({
        status: 'OK',
        message: 'Conexión a la base de datos exitosa',
        database: process.env.DB_NAME || 'AppContractor',
      });
    } else {
      res.status(500).json({
        status: 'ERROR',
        message: 'No se pudo conectar a la base de datos',
      });
    }
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: error.message,
    });
  }
});

// Middleware de manejo de errores global (debe ir al final, después de todas las rutas)
app.use((err, req, res, next) => {
  console.error('❌ Error en middleware:', err);
  console.error('Stack:', err.stack);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Error interno del servidor',
  });
});

// Manejo de rutas no encontradas
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Ruta no encontrada',
    path: req.path,
  });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  console.log(`🌐 Accesible desde: http://0.0.0.0:${PORT}`);
  console.log(`📦 Entorno: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📡 Rutas disponibles:`);
  console.log(`   - POST /api/register/contratista`);
  console.log(`   - POST /api/register/trabajador`);
  console.log(`   - POST /api/auth/login`);
  console.log(`   - GET /api/auth/verify`);
  console.log(`   - GET /api/categorias`);
  console.log(`   - PUT /api/ubicacion/contratista`);
  console.log(`   - PUT /api/ubicacion/trabajador`);
  console.log(`   - GET /api/ubicacion/trabajadores-cercanos?email=...&radio=500`);
  console.log(`   - GET /api/ubicacion/trabajadores-por-categoria?email=...&categoria=...&radio=500`);
  console.log(`   - GET /api/ubicacion/contratistas-cercanos?email=...&radio=500`);
  console.log(`   - GET /api/contratistas/perfil?email=...`);
  console.log(`   - PUT /api/contratistas/perfil`);
  console.log(`   - GET /api/trabajadores/perfil?email=...`);
  console.log(`   - POST /api/asignaciones/asignar`);
  console.log(`   - POST /api/asignaciones/cancelar`);
  console.log(`   - POST /api/asignaciones/finalizar`);
  console.log(`   - GET /api/calificaciones/trabajador?emailTrabajador=...`);
  console.log(`   - POST /api/notificaciones/token`);
  console.log(`   - DELETE /api/notificaciones/token`);
  console.log(`   - GET /api/notificaciones?email=...&tipoUsuario=...`);
  console.log(`   - POST /api/notificaciones/marcar-leidas`);
  console.log(`   - POST /api/solicitudes/aplicar`);
  console.log(`   - GET /api/solicitudes/pendiente?emailTrabajador=...`);
  console.log(`   - GET /api/health`);
  
  // Probar conexión a la base de datos al iniciar
  await testConnection();
});

export default app;

