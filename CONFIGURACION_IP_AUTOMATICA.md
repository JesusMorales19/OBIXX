# 🌐 Configuración Automática de IP del Servidor

## ✅ Implementación Completada

Se ha implementado un sistema automático de detección y configuración de IP del servidor que funciona en todos los dispositivos.

## 🎯 Funcionalidades

### 1. **Detección Automática por Plataforma**
   - **Android Emulador**: Usa `10.0.2.2` por defecto
   - **Android Dispositivo Físico**: El usuario puede configurar la IP manualmente
   - **iOS Simulador**: Usa `localhost` por defecto
   - **Web/Desktop**: Usa `localhost` por defecto

### 2. **Configuración Persistente**
   - La IP configurada se guarda en `SharedPreferences`
   - La configuración persiste entre sesiones de la app
   - No necesitas volver a configurarla cada vez

### 3. **Configuración Manual**
   - Botón "Configurar servidor" en la pantalla de login
   - Diálogo fácil de usar para cambiar IP y puerto
   - Validación de IP y puerto
   - Consejos según la plataforma

## 📁 Archivos Creados/Modificados

### Nuevos Archivos:
- ✅ `lib/services/config_service.dart` - Servicio para manejar la configuración de IP
- ✅ `lib/widgets/server_config_dialog.dart` - Diálogo para configurar el servidor

### Archivos Modificados:
- ✅ `lib/services/api_service.dart` - Ahora usa `ConfigService` para obtener la URL
- ✅ `lib/views/screens/login/login_view.dart` - Agregado botón de configuración

## 🚀 Cómo Funciona

### Primera Vez (Sin Configuración)
1. La app detecta automáticamente la plataforma
2. Usa la IP por defecto según la plataforma:
   - Android: `10.0.2.2:3000/api`
   - iOS/Web: `localhost:3000/api`

### Para Dispositivos Físicos Android
1. El usuario debe configurar manualmente la IP de su PC
2. Para encontrar la IP de tu PC:
   - **Windows**: Abre CMD y ejecuta `ipconfig`
   - Busca "Dirección IPv4" (ej: `192.168.1.100`)
   - **Mac/Linux**: Abre terminal y ejecuta `ifconfig` o `ip addr`
   - Busca la IP que empiece con `192.168.x.x` o `10.0.x.x`

3. Configuración:
   - Toca el botón "Configurar servidor" en el login
   - Ingresa la IP de tu PC (ej: `192.168.1.100`)
   - Ingresa el puerto (por defecto: `3000`)
   - Guarda la configuración

### La Configuración se Guarda
- Una vez configurada, la app recordará la IP
- No necesitas volver a configurarla cada vez
- Funciona incluso si cierras y abres la app

## 📱 Uso en el Login

En la pantalla de login, encontrarás un botón pequeño:
- **"Configurar servidor"** (icono de engranaje)
- Al tocarlo, se abre un diálogo para configurar IP y puerto
- Incluye consejos según tu plataforma

## 🔧 Ejemplo de Configuración

### Escenario 1: Android Emulador
- **IP**: `10.0.2.2` (automático)
- **Puerto**: `3000`
- **URL**: `http://10.0.2.2:3000/api`

### Escenario 2: Dispositivo Físico Android
- **IP**: `192.168.1.100` (la IP de tu PC en la red)
- **Puerto**: `3000`
- **URL**: `http://192.168.1.100:3000/api`
- **Nota**: Tu PC y celular deben estar en la misma red WiFi

### Escenario 3: iOS Simulador / Web
- **IP**: `localhost` (automático)
- **Puerto**: `3000`
- **URL**: `http://localhost:3000/api`

## ⚠️ Importante

1. **Misma Red WiFi**: Para dispositivos físicos, tu PC y celular deben estar en la misma red WiFi
2. **Firewall**: Asegúrate de que el firewall de Windows permita conexiones en el puerto 3000
3. **Servidor Corriendo**: El servidor backend debe estar corriendo en tu PC

## 🛠️ Verificar Configuración Actual

La app muestra la URL actual en el diálogo de configuración, así puedes verificar qué IP está usando.

## 💡 Ventajas

✅ **Automático**: Funciona sin configuración en emuladores
✅ **Persistente**: Guarda la configuración entre sesiones
✅ **Fácil**: Botón accesible en el login para cambiar si es necesario
✅ **Inteligente**: Detecta la plataforma y usa valores por defecto apropiados

