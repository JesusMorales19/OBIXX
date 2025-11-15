# 📱 Solución: Conexión desde Celular Físico

## 🔍 Problema
La app en tu celular físico no puede conectarse al servidor porque está usando `localhost` o `10.0.2.2` (que solo funciona en emulador).

## ✅ Solución: Configurar la IP de tu PC

### Paso 1: Encontrar la IP de tu PC

**En Windows:**
1. Abre el **Símbolo del sistema** (CMD) o **PowerShell**
2. Escribe: `ipconfig`
3. Presiona Enter
4. Busca **"Dirección IPv4"** o **"IPv4 Address"** en la sección de tu adaptador WiFi o Ethernet
5. Anota esa IP (ejemplo: `192.168.1.100` o `192.168.0.50`)

**Ejemplo de salida:**
```
Adaptador de LAN inalámbrica Wi-Fi:
   Dirección IPv4 . . . . . . . . . . . . . . : 192.168.1.100
```

### Paso 2: Configurar la IP en la App

1. **Abre la app** en tu celular
2. En la **pantalla de login**, busca el botón **"Configurar servidor"** (abajo, con icono de engranaje ⚙️)
3. **Toca ese botón**
4. Se abrirá un diálogo de configuración
5. **Ingresa la IP de tu PC** (la que encontraste en el paso 1)
   - Ejemplo: `192.168.1.100`
6. **Ingresa el puerto**: `3000`
7. **Toca "Guardar"**

### Paso 3: Verificar que Funcione

1. **Asegúrate de que:**
   - Tu PC y celular están en la **misma red WiFi**
   - El servidor backend está corriendo en tu PC (`npm start` en la carpeta `backend`)
   - El firewall de Windows permite conexiones en el puerto 3000

2. **Intenta registrar** o hacer login nuevamente

## ⚠️ Requisitos Importantes

1. **Misma Red WiFi**: Tu PC y celular deben estar conectados a la misma red WiFi
2. **Servidor Corriendo**: El backend debe estar corriendo en tu PC
3. **Firewall**: Asegúrate de que el firewall de Windows no bloquee el puerto 3000

## 🔧 Si Aún No Funciona

### Verificar Firewall de Windows

1. Abre **Windows Defender Firewall**
2. Ve a **Configuración avanzada**
3. Crea una regla de entrada para el puerto 3000:
   - Tipo: Puerto
   - Protocolo: TCP
   - Puerto: 3000
   - Acción: Permitir la conexión

### Verificar que el Servidor Esté Accesible

En tu PC, abre el navegador y ve a:
- `http://TU_IP:3000/api/health`
- Ejemplo: `http://192.168.1.100:3000/api/health`

Si no carga, el servidor no está accesible desde la red.

## 📝 Ejemplo Completo

Si tu PC tiene IP `192.168.1.100`:

1. En la app, toca "Configurar servidor"
2. IP: `192.168.1.100`
3. Puerto: `3000`
4. Guarda
5. La app ahora usará: `http://192.168.1.100:3000/api`

