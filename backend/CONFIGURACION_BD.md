# Configuración de Base de Datos PostgreSQL

## 📋 Pasos para Configurar la Conexión

### 1. Crear el archivo `.env`

Crea un archivo `.env` en la carpeta `backend/` con el siguiente contenido:

```env
# Configuración de la base de datos PostgreSQL
DB_USER=postgres
DB_HOST=localhost
DB_NAME=AppContractor
DB_PASSWORD=tu_contraseña_aqui
DB_PORT=5432

# Configuración del servidor
PORT=3000
NODE_ENV=development

# Configuración de CORS (opcional)
CORS_ORIGIN=http://localhost:3000
```

**⚠️ IMPORTANTE:** 
- Reemplaza `tu_contraseña_aqui` con la contraseña real de tu usuario de PostgreSQL
- Si tu usuario de PostgreSQL no es `postgres`, cambia `DB_USER` con tu usuario

### 2. Verificar que PostgreSQL esté corriendo

Asegúrate de que:
- PostgreSQL esté instalado y corriendo
- La base de datos `AppContractor` exista (si no existe, créala)
- El puerto 5432 esté disponible

### 3. Crear la base de datos (si no existe)

Si la base de datos `AppContractor` no existe, créala con:

```sql
CREATE DATABASE "AppContractor";
```

O usando psql:
```bash
psql -U postgres -c "CREATE DATABASE \"AppContractor\";"
```

### 4. Iniciar el servidor

Desde la carpeta `backend/`, ejecuta:

```bash
npm start
```

O si prefieres usar nodemon para desarrollo:

```bash
npm install -g nodemon
nodemon server.js
```

### 5. Verificar la conexión

Una vez iniciado el servidor, puedes verificar la conexión visitando:

- **Servidor**: http://localhost:3000
- **Health Check**: http://localhost:3000/api/health

## ✅ Estructura de Archivos Creados

```
backend/
├── config/
│   └── database.js      # Configuración y conexión a PostgreSQL
├── server.js            # Servidor Express con rutas
├── .env                 # Variables de entorno (crear manualmente)
└── package.json         # Dependencias del proyecto
```

## 🔧 Funciones Disponibles en `database.js`

- `testConnection()`: Prueba la conexión a la base de datos
- `query(text, params)`: Ejecuta consultas SQL
- `getClient()`: Obtiene un cliente del pool de conexiones
- `pool`: Pool de conexiones de PostgreSQL (exportado por defecto)

## 📝 Ejemplo de Uso

```javascript
import { query, testConnection } from './config/database.js';

// Probar conexión
await testConnection();

// Ejecutar una consulta
const result = await query('SELECT * FROM usuarios WHERE id = $1', [1]);
console.log(result.rows);
```

## 🐛 Solución de Problemas

### Error: "password authentication failed"
- Verifica que la contraseña en `.env` sea correcta
- Verifica que el usuario de PostgreSQL exista

### Error: "database does not exist"
- Crea la base de datos `AppContractor` primero
- Verifica que el nombre en `.env` sea correcto

### Error: "connection refused"
- Verifica que PostgreSQL esté corriendo
- Verifica que el puerto 5432 esté disponible
- Verifica que el host sea correcto (localhost por defecto)

