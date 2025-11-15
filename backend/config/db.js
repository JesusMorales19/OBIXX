import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// Configuración de la conexión a PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'AppContractor',
  password: process.env.DB_PASSWORD || '',
  port: process.env.DB_PORT || 5432,
  // Configuraciones adicionales para conexiones más robustas
  max: 20, // Número máximo de clientes en el pool
  idleTimeoutMillis: 30000, // Tiempo de espera antes de cerrar clientes inactivos
  connectionTimeoutMillis: 2000, // Tiempo máximo para establecer conexión
});

// Manejo de errores en el pool
pool.on('error', (err, client) => {
  console.error('❌ Error inesperado en el cliente inactivo:', err);
  console.error('Stack:', err.stack);
  // No cerrar el proceso, solo registrar el error
  // El pool se encargará de reconectar automáticamente
});

// Función para probar la conexión
export const testConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('✅ Conexión a PostgreSQL exitosa');
    console.log(`📊 Base de datos: ${process.env.DB_NAME || 'AppContractor'}`);
    console.log(`🔌 Puerto: ${process.env.DB_PORT || 5432}`);
    client.release();
    return true;
  } catch (error) {
    console.error('❌ Error al conectar con PostgreSQL:', error.message);
    return false;
  }
};

// Función para ejecutar consultas
export const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    // Solo loggear consultas lentas (> 1 segundo) o en modo desarrollo
    if (duration > 1000 || process.env.NODE_ENV === 'development') {
      console.log('⏱️ Consulta ejecutada', { duration: `${duration}ms`, rows: res.rowCount });
    }
    return res;
  } catch (error) {
    console.error('❌ Error en la consulta:', error.message);
    console.error('Query:', text.substring(0, 100) + '...');
    throw error;
  }
};

// Función para obtener un cliente del pool
export const getClient = async () => {
  const client = await pool.connect();
  const query = client.query;
  const release = client.release;
  
  // Establecer un timeout en el cliente
  const timeout = setTimeout(() => {
    console.error('Un cliente ha estado inactivo por más de 5 segundos');
    console.error('Stack trace:', new Error().stack);
  }, 5000);
  
  // Monitorear el cliente para detectar errores
  client.on('error', (err) => {
    console.error('Error en el cliente:', err);
    clearTimeout(timeout);
  });
  
  // Override de release para limpiar el timeout
  client.release = () => {
    clearTimeout(timeout);
    return release.apply(client);
  };
  
  return client;
};

export default pool;

