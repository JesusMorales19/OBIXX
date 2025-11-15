# 🔧 Solución al Error de Conexión

## ❌ Error Mostrado
```
Error de conexión: ClientException: Failed to fetch, 
uri=http://10.0.2.2:3000/api/register/contratista
```

## 🔍 Causas Posibles

### 1. **El servidor backend no está corriendo**
   - ✅ **Solución**: Inicia el servidor backend
   ```bash
   cd backend
   npm start
   ```

### 2. **URL incorrecta para tu plataforma**
   - **Android Emulador**: `http://10.0.2.2:3000/api`
   - **Dispositivo Físico**: `http://TU_IP_LOCAL:3000/api` (ej: `http://192.168.1.100:3000/api`)
   - **Web/Desktop**: `http://localhost:3000/api`
   - **iOS Simulador**: `http://localhost:3000/api`

### 3. **Puerto 3000 bloqueado o en uso**
   - ✅ **Solución**: Verifica que el puerto 3000 esté disponible

---

## 🚀 Pasos para Solucionar

### Paso 1: Verificar que el Backend esté Corriendo

1. Abre una terminal en la carpeta `backend`
2. Ejecuta:
   ```bash
   npm start
   ```
3. Deberías ver:
   ```
   🚀 Servidor corriendo en http://localhost:3000
   ✅ Conexión a PostgreSQL exitosa
   ```

### Paso 2: Verificar la Conexión desde el Navegador

Abre tu navegador y ve a:
- `http://localhost:3000` - Debería mostrar un mensaje JSON
- `http://localhost:3000/api/health` - Debería mostrar el estado de la BD

### Paso 3: Configurar la URL Correcta en Flutter

Abre `lib/services/api_service.dart` y ajusta la URL según tu plataforma:

**Para Android Emulador (por defecto):**
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

**Para Dispositivo Físico:**
1. Encuentra tu IP local:
   - Windows: `ipconfig` en CMD
   - Mac/Linux: `ifconfig` en terminal
   - Busca la IP que empiece con `192.168.x.x`
2. Cambia la URL:
   ```dart
   static const String baseUrl = 'http://192.168.1.XXX:3000/api';
   ```

**Para Web/Desktop:**
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### Paso 4: Verificar el Firewall

Si estás usando un **dispositivo físico**, asegúrate de que:
- El firewall de Windows permita conexiones en el puerto 3000
- El antivirus no esté bloqueando la conexión

### Paso 5: Verificar la Configuración de Red

Si estás en **Android Emulador** y sigue sin funcionar:
1. Verifica que el emulador tenga acceso a internet
2. Prueba con `http://localhost:3000/api` si el emulador lo permite

---

## 🧪 Prueba de Conexión

Puedes probar manualmente la conexión desde Flutter añadiendo un botón de prueba:

```dart
// En cualquier pantalla de prueba
ElevatedButton(
  onPressed: () async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/health'),
      );
      print('✅ Conexión exitosa: ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  },
  child: Text('Probar Conexión'),
)
```

---

## 📝 Checklist de Verificación

Antes de intentar registrar, verifica:

- [ ] El servidor backend está corriendo (`npm start` en `backend/`)
- [ ] La URL en `api_service.dart` es correcta para tu plataforma
- [ ] El puerto 3000 no está bloqueado
- [ ] PostgreSQL está corriendo y la conexión funciona
- [ ] Las tablas `contratistas` y `trabajadores` existen en la BD
- [ ] El archivo `.env` en `backend/` está configurado correctamente

---

## 🐛 Si el Problema Persiste

1. **Revisa los logs del servidor backend** cuando intentas registrar
2. **Revisa la consola de Flutter** para ver mensajes de depuración
3. **Verifica la conexión de red** entre tu dispositivo y la computadora
4. **Prueba con Postman o curl** para verificar que el endpoint funciona:
   ```bash
   curl -X POST http://localhost:3000/api/register/contratista \
     -H "Content-Type: application/json" \
     -d '{"nombre":"Test","apellido":"User","email":"test@test.com","telefono":"1234567890","password":"Test1234"}'
   ```

---

## ✅ Solución Rápida

Si estás en **Windows** y usando un **emulador de Android**, prueba cambiando la URL a:

```dart
// En lib/services/api_service.dart
static const String baseUrl = 'http://localhost:3000/api';
```

O si estás usando un **dispositivo físico**, usa tu IP local:

```dart
static const String baseUrl = 'http://192.168.1.XXX:3000/api';
```

---

¡Espero que esto resuelva el problema! 🎉











