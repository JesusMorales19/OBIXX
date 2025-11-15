# 📡 Conexión Frontend-Backend - Registro de Usuarios

## ✅ Implementación Completada

Se ha conectado exitosamente el frontend de Flutter con el backend de Node.js para el registro de contratistas y trabajadores.

---

## 🎯 Funcionalidades Implementadas

### 1. **Registro de Contratista**
- ✅ Campos: nombre, apellido, email, género, teléfono, password
- ✅ Generación automática del campo `user` desde el email
- ✅ Validación de email único
- ✅ Validación de user único (si existe, añade número)

### 2. **Registro de Trabajador**
- ✅ Campos: nombre, apellido, fecha de nacimiento, email, género, teléfono, experiencia, categoría, password
- ✅ Generación automática del campo `user` desde el email
- ✅ Validación de email único
- ✅ Validación de user único (si existe, añade número)
- ✅ Manejo de categorías (FK a tabla categorias)

---

## 📁 Archivos Creados/Modificados

### Backend:
- ✅ `backend/utils/emailUtils.js` - Utilidades para extraer user del email y convertir fechas
- ✅ `backend/controllers/registerController.js` - Controladores para registro
- ✅ `backend/routes/registerRoutes.js` - Rutas de registro
- ✅ `backend/server.js` - Actualizado para incluir rutas de registro

### Frontend:
- ✅ `lib/models/contratista_model.dart` - Modelo de datos para contratista
- ✅ `lib/models/trabajador_model.dart` - Modelo de datos para trabajador
- ✅ `lib/services/api_service.dart` - Servicio para peticiones HTTP
- ✅ `lib/views/screens/register/register_contratista.dart` - Actualizado para usar API
- ✅ `lib/views/screens/register/register_trabajador.dart` - Actualizado para usar API

---

## 🚀 Cómo Usar

### 1. **Configurar el Backend**

Asegúrate de tener el archivo `.env` en la carpeta `backend/`:

```env
DB_USER=postgres
DB_HOST=localhost
DB_NAME=AppContractor
DB_PASSWORD=tu_contraseña
DB_PORT=5432
PORT=3000
NODE_ENV=development
```

### 2. **Iniciar el Backend**

```bash
cd backend
npm start
```

El servidor debería estar corriendo en `http://localhost:3000`

### 3. **Configurar la URL del API en Flutter**

Si estás usando un **emulador de Android**, la URL ya está configurada:
- `http://10.0.2.2:3000/api` (configurado por defecto)

Si estás usando un **dispositivo físico** o **web**, modifica `lib/services/api_service.dart`:

```dart
// Para dispositivo físico, usa tu IP local:
static const String baseUrl = 'http://192.168.1.XXX:3000/api';

// Para web:
static const String baseUrl = 'http://localhost:3000/api';
```

### 4. **Probar el Registro**

1. Ejecuta la app Flutter
2. Ve a "Register"
3. Selecciona "Contratista" o "Trabajador"
4. Completa el formulario
5. Al hacer clic en "Registrar", los datos se enviarán al backend
6. El campo `user` se generará automáticamente desde el email

---

## 🔧 Funcionamiento Técnico

### Generación Automática del `user`

El sistema extrae automáticamente el `user` del email:
- **Email**: `jesuhernan232@gmail.com`
- **User generado**: `jesuhernan232`

Si el `user` ya existe, se añade un número al final:
- Primer intento: `jesuhernan232`
- Si existe: `jesuhernan2321`
- Si existe: `jesuhernan2322`
- Y así sucesivamente...

### Estructura de Datos

**Contratistas:**
```sql
nombre, apellido, user, email, telefono, password, created_at
```

**Trabajadores:**
```sql
nombre, apellido, user, email, fechaNaciemiento, telefono, password, 
categoria (FK), experiencia, disponible, calificacion_promedio, created_at
```

---

## 🐛 Solución de Problemas

### Error: "Error de conexión"
- ✅ Verifica que el backend esté corriendo (`npm start` en la carpeta `backend`)
- ✅ Verifica que la URL en `api_service.dart` sea correcta
- ✅ Para Android emulador usa: `http://10.0.2.2:3000/api`
- ✅ Para dispositivo físico, usa tu IP local (ej: `http://192.168.1.100:3000/api`)

### Error: "El email ya está registrado"
- ✅ Este es un comportamiento esperado. El email debe ser único.

### Error: "Error interno del servidor"
- ✅ Verifica que PostgreSQL esté corriendo
- ✅ Verifica que las tablas existan en la base de datos
- ✅ Revisa los logs del servidor backend para más detalles

---

## 📝 Notas Importantes

1. **El campo `user` se genera automáticamente** - El usuario NO lo ingresa manualmente
2. **Las fechas se convierten automáticamente** de DD/MM/YYYY a YYYY-MM-DD para PostgreSQL
3. **Las categorías se crean automáticamente** si no existen en la tabla `categorias`
4. **Los trabajadores se registran como `disponible = true`** por defecto
5. **La calificación promedio inicia en 0.0** para trabajadores

---

## ✅ Próximos Pasos Sugeridos

1. Implementar el login con autenticación real
2. Agregar hashing de contraseñas (bcrypt)
3. Implementar tokens JWT para sesiones
4. Agregar validación de campos en el backend
5. Implementar manejo de errores más robusto

---

¡Listo! El registro de contratistas y trabajadores ya está conectado y funcionando. 🎉











