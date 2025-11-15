# 📋 MAPEO COMPLETO DE NOTIFICACIONES

## 📍 UBICACIÓN DE FUNCIONES DE NOTIFICACIÓN

### Backend - Servicios de Notificación

#### 1. `backend/services/notificationService.js`
**Funciones definidas:**
- `crearNotificacion()` - Línea 44: Crea registro en BD
- `notificarCalificacionTrabajador()` - Línea 151: Notifica calificación al trabajador
- `notificarInteresContratista()` - Línea 211: Notifica interés del contratista
- `notificarCancelacionContratista()` - Línea 261: Notifica cancelación por contratista
- `notificarCancelacionTrabajador()` - Línea 305: Notifica cancelación por trabajador
- `obtenerTokensUsuario()` - Línea 33: Obtiene tokens FCM del usuario

#### 2. `backend/services/solicitudesService.js`
**Funciones definidas:**
- `enviarNotificacionRechazo()` - Línea 62: Notifica rechazo de solicitud
- `expirarSolicitudesPendientes()` - Línea 109: Expira solicitudes y envía notificación
- `marcarSolicitudesComoRechazadas()` - Línea 193: Marca como rechazadas y envía notificación

#### 3. `backend/services/firebaseService.js`
**Función definida:**
- `sendPushNotification()` - Línea 98: Envía push notification vía Firebase

---

## 🔔 NOTIFICACIONES Y DÓNDE SE LLAMAN

### 1. NOTIFICACIÓN: Trabajador aplica a trabajo
**Dirección:** Trabajador → Contratista

**Función que la envía:**
- `backend/controllers/solicitudesController.js`
  - Función: `aplicarATrabajo()` - Línea 17
  - Llama a: `crearNotificacion()` - Línea 192
  - Llama a: `sendPushNotification()` - Línea 214

**Botón que la dispara:**
- `lib/views/screens/trabajador/home_view.dart`
  - Botón: "Aplicar Ahora" en `WorkerCard`
  - Función: `_aplicarTrabajo()` - Línea 161
  - Llama a: `ApiService.aplicarASolicitud()` - Línea 208

- `lib/views/screens/trabajador/see_more_jobs.dart`
  - Botón: "Aplicar Ahora" en `WorkerCard`
  - Función: `_aplicarTrabajo()` - Línea 306
  - Llama a: `ApiService.aplicarASolicitud()` - Línea 359

**Mensaje:**
```
"[Nombre Trabajador] se interesó en el proyecto '[Título]'. Recuerda que puedes contactarlo por WhatsApp en caso de aceptarlo."
```

---

### 2. NOTIFICACIÓN: Contratista acepta solicitud
**Dirección:** Contratista → Trabajador

**Función que la envía:**
- `backend/controllers/asignacionesController.js`
  - Función: `asignarTrabajo()` - Línea 15
  - Llama a: `crearNotificacion()` - Línea 204 (solo si hay `idSolicitud`)
  - Llama a: `sendPushNotification()` - Línea 220 (solo si hay `idSolicitud`)

**Botón que la dispara:**
- `lib/views/widgets/notifications_overlay.dart`
  - Botón: "Aceptar" en overlay de notificación
  - Función: `_aceptarSolicitud()` - Línea 220
  - Llama a: `NotificationService.aceptarSolicitud()` - Línea 223
  - Que llama a: `ApiService.asignarTrabajo()` - Línea 231

**Mensaje:**
```
"Aceptó tu solicitud para el proyecto '[Título]'. Mantente al tanto de tu WhatsApp, por ahí te contactará."
```

---

### 3. NOTIFICACIÓN: Contratista asigna trabajo directo (sin solicitud)
**Dirección:** Contratista → Trabajador

**Función que la envía:**
- `backend/controllers/asignacionesController.js`
  - Función: `asignarTrabajo()` - Línea 15
  - Llama a: `notificarInteresContratista()` - Línea 237 (solo si NO hay `idSolicitud`)

**Botón que la dispara:**
- `lib/views/widgets/contratista/home_view/worker_card.dart`
  - Botón: "Contratar" o similar
  - Llama a: `ApiService.asignarTrabajo()` (sin `idSolicitud`)

**Mensaje:**
```
"El contratista [Nombre] se ha interesado en ti. Mantente al tanto de tu WhatsApp, ahí te contactará."
```

---

### 4. NOTIFICACIÓN: Solicitud rechazada (automática al borrar notificaciones)
**Dirección:** Sistema → Trabajador

**Función que la envía:**
- `backend/services/solicitudesService.js`
  - Función: `marcarSolicitudesComoRechazadas()` - Línea 193
  - Llama a: `enviarNotificacionRechazo()` - Línea 254

**Botón que la dispara:**
- `lib/views/widgets/notifications_overlay.dart`
  - Botón: "Borrar notificaciones" - Línea 87
  - Función: `NotificationService.deleteAll()` - Línea 86
  - Que llama a: `ApiService.eliminarNotificaciones()` - Línea 152
  - Backend: `backend/controllers/notificacionesController.js`
    - Función: `eliminarNotificaciones()` - Línea 122
    - Llama a: `marcarSolicitudesComoRechazadas()` - Línea 164

**Mensaje:**
```
"Ha rechazado/cancelado la solicitud hacia el proyecto '[Título]'. Ahora estás disponible para más proyectos y distintos contratistas."
```

---

### 5. NOTIFICACIÓN: Solicitud expirada (automática)
**Dirección:** Sistema → Trabajador

**Función que la envía:**
- `backend/services/solicitudesService.js`
  - Función: `expirarSolicitudesPendientes()` - Línea 109
  - Llama a: `enviarNotificacionRechazo()` - Línea 167

**Cuándo se dispara:**
- Automático: Se ejecuta cada vez que se llama a `expirarSolicitudesPendientes()`
- Se llama desde:
  - `backend/controllers/solicitudesController.js` - Línea 34 (al aplicar)
  - `backend/controllers/notificacionesController.js` - Línea 79 (al listar notificaciones)
  - Otros lugares donde se verifica solicitudes

**Mensaje:**
```
"Ha rechazado/cancelado la solicitud hacia el proyecto '[Título]'. Ahora estás disponible para más proyectos y distintos contratistas."
```

---

### 6. NOTIFICACIÓN: Trabajador cancela contrato
**Dirección:** Trabajador → Contratista

**Función que la envía:**
- `backend/services/notificationService.js`
  - Función: `notificarCancelacionTrabajador()` - Línea 305
  - Llama a: `crearNotificacion()` - Línea 319
  - Llama a: `sendPushNotification()` - Línea 335

**Botón que la dispara:**
- `lib/views/widgets/trabajador/jobs_employee/worker_card_jobs.dart`
  - Botón: "Cancelar contrato" - Línea 294
  - Función: `onCancelarContrato` callback
- `lib/views/screens/trabajador/jobs_employee.dart`
  - Función: `_finalizarContrato()` - Línea 108
  - Llama a: `ApiService.cancelarAsignacion()` - Línea 126
    - Con: `iniciadoPorTrabajador: true` y `skipDefaultNotification: true`
- `backend/controllers/asignacionesController.js`
  - Función: `cancelarAsignacion()` - Línea 272
  - Llama a: `notificarCancelacionTrabajador()` - Línea 452 (si `canceladoPorTrabajador` es true)

**Mensaje:**
```
"El trabajador perteneciente al proyecto '[Título]' canceló su instancia."
```

---

### 7. NOTIFICACIÓN: Contratista cancela asignación
**Dirección:** Contratista → Trabajador

**Función que la envía:**
- `backend/services/notificationService.js`
  - Función: `notificarCancelacionContratista()` - Línea 261
  - Llama a: `crearNotificacion()` - Línea 273
  - Llama a: `sendPushNotification()` - Línea 288

**Botón que la dispara:**
- `lib/views/screens/contratista/home_view.dart`
  - Botón: "Cancelar Asignación" - Línea 350, 407
  - Función: `_cancelarAsignacion()` - Línea 486
  - Llama a: `ApiService.cancelarAsignacion()` - Línea 490
    - Con: `skipDefaultNotification: true` ⚠️ **PROBLEMA: No se envía notificación**

- `lib/views/screens/contratista/see_more_employees.dart`
  - Botón: "Cancelar Asignación" - Línea 342
  - Función: `_cancelarAsignacion()` - Línea 235
  - Llama a: `ApiService.cancelarAsignacion()` - Línea 242
    - Sin `skipDefaultNotification` ⚠️ **PERO la lógica del backend no envía notificación**

- `lib/views/widgets/contratista/jobs_active/rate_worker_modal.dart`
  - Botón: "Finalizar" (después de calificar)
  - Llama a: `ApiService.cancelarAsignacion()` - Línea 131
    - Sin `skipDefaultNotification` ⚠️ **PERO la lógica del backend no envía notificación**

**Mensaje (NO SE ENVÍA ACTUALMENTE):**
```
"[Nombre Contratista] ha cancelado la contratación. Ahora estás disponible hacia más proyectos y distintos contratistas."
```

**Problema:** La lógica en `cancelarAsignacion()` solo envía notificación si `canceladoPorTrabajador` es true (línea 401), pero cuando el contratista cancela, `canceladoPorTrabajador` es false.

---

### 8. NOTIFICACIÓN: Contratista finaliza trabajo y califica
**Dirección:** Contratista → Trabajador

**Función que la envía:**
- `backend/services/notificationService.js`
  - Función: `notificarCalificacionTrabajador()` - Línea 151
  - Llama a: `crearNotificacion()` - Línea 176
  - Llama a: `sendPushNotification()` - Línea 193

**Botón que la dispara:**
- `backend/controllers/asignacionesController.js`
  - Función: `finalizarTrabajo()` - Línea 759
  - Llama a: `notificarCalificacionTrabajador()` - Línea 973

**Frontend:**
- `lib/views/widgets/contratista/jobs_active/rate_worker_modal.dart`
  - Botón: "Enviar Calificación" - Línea ~144
  - Llama a: `ApiService.finalizarTrabajo()` - Línea ~144

**Mensaje:**
```
"El contratista [Nombre] ha terminado el trabajo '[Título]' y registró tu calificación. Tu valoración fue de [X]/5 estrellas."
```

---

## 📊 RESUMEN DE LLAMADAS

### Backend - Controladores que llaman notificaciones:

1. **`backend/controllers/solicitudesController.js`**
   - `aplicarATrabajo()` → Crea notificación cuando trabajador aplica

2. **`backend/controllers/asignacionesController.js`**
   - `asignarTrabajo()` → Crea notificación cuando acepta solicitud o asigna directo
   - `cancelarAsignacion()` → Llama `notificarCancelacionTrabajador()` si trabajador cancela
   - `finalizarTrabajo()` → Llama `notificarCalificacionTrabajador()`

3. **`backend/controllers/notificacionesController.js`**
   - `eliminarNotificaciones()` → Llama `marcarSolicitudesComoRechazadas()`
   - `registrarInteresContratista()` → Llama `notificarInteresContratista()`
   - `registrarCancelacionContratista()` → Llama `notificarCancelacionContratista()`

4. **`backend/services/solicitudesService.js`**
   - `expirarSolicitudesPendientes()` → Llama `enviarNotificacionRechazo()`
   - `marcarSolicitudesComoRechazadas()` → Llama `enviarNotificacionRechazo()`

---

## ⚠️ PROBLEMAS IDENTIFICADOS

### 1. Contratista cancela asignación - NO ENVÍA NOTIFICACIÓN
**Ubicación:** `backend/controllers/asignacionesController.js` - Línea 400-448

**Problema:** 
- La lógica solo envía notificación si `canceladoPorTrabajador` es true
- Cuando el contratista cancela, `canceladoPorTrabajador` es false
- Por lo tanto, NO se envía notificación al trabajador

**Solución necesaria:**
- Agregar lógica para enviar `notificarCancelacionContratista()` cuando el contratista cancela

---

## 📝 NOTAS IMPORTANTES

1. **`skipDefaultNotification`**: Algunas llamadas usan este flag para evitar notificaciones por defecto
2. **`canceladoPorTrabajador`**: Determina quién inició la cancelación
3. **`idSolicitud`**: Si existe, significa que hubo una solicitud previa; si no, es asignación directa
4. **Expiración automática**: Las solicitudes expiran después de 10 minutos automáticamente

