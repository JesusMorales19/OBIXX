# 🔥 Permitir Puerto 3000 en el Firewall de Windows

## Pasos para Permitir el Puerto 3000

### Opción 1: Desde PowerShell (Rápido)

1. Abre **PowerShell como Administrador** (clic derecho → Ejecutar como administrador)
2. Ejecuta este comando:
```powershell
New-NetFirewallRule -DisplayName "Node.js Server Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Opción 2: Desde la Interfaz Gráfica

1. Presiona `Windows + R`
2. Escribe: `wf.msc` y presiona Enter (se abre el Firewall de Windows)
3. En el panel izquierdo, haz clic en **"Reglas de entrada"**
4. En el panel derecho, haz clic en **"Nueva regla..."**
5. Selecciona **"Puerto"** → Siguiente
6. Selecciona **"TCP"** y **"Puertos locales específicos"**
7. Escribe: `3000` → Siguiente
8. Selecciona **"Permitir la conexión"** → Siguiente
9. Marca todas las casillas (Dominio, Privada, Pública) → Siguiente
10. Nombre: `Node.js Server Port 3000` → Finalizar

## Verificar que Funciona

Después de configurar el firewall, prueba desde tu celular:
1. Abre la app
2. Configura la IP: `192.168.0.112`
3. Puerto: `3000`
4. Intenta registrar

