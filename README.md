## OBIX - Documentación del Proyecto

Este README describe de forma clara y completa cómo funciona la app (Flutter), el backend (Node.js + Express) y la base de datos (PostgreSQL), incluyendo arquitectura, librerías utilizadas, variables de entorno, notificaciones push (FCM), generación de PDF de nómina, y relación entre entidades principales. Está pensado para que cualquier persona pueda entender qué se hizo y cómo ejecutar todo.


### Índice
- Descripción general
- Arquitectura (alto nivel)
- Flujo de datos
- Frontend (Flutter)
- Backend (Node.js + Express)
- Base de datos (PostgreSQL)
- Notificaciones Push (Firebase Cloud Messaging)
- Generación de PDF de Nómina
- Variables de entorno (Render)
- Despliegue en Render (Backend y DB)
- Backup y Restore de la base de datos
- Seguridad, logs y salud del servicio


### Descripción general
OBIX es una plataforma que conecta contratistas con trabajadores para trabajos de corto y largo plazo. La app móvil está desarrollada en Flutter y se comunica con un backend en Node.js/Express por medio de una API REST. Los datos se almacenan en PostgreSQL. El sistema soporta notificaciones push (FCM), asignación de trabajos, solicitudes, calificaciones, favoritos y un módulo premium con generación de nóminas en PDF, registro de horas y gastos extra.


### Arquitectura (alto nivel)
La arquitectura actual (minimalista y clara) es la siguiente:

```mermaid
flowchart LR
  Flutter["📱 Flutter App"]:::app -->|HTTP JSON| API["🔗 API REST"]:::api --> BE["⚙️ Node.js + Express"]:::be
  BE --> DB["🐘 PostgreSQL"]:::db
  BE --> FCM["🔔 Firebase Cloud Messaging"]:::svc

  classDef app fill:#06b6d4,stroke:#0e7490,color:#fff,stroke-width:2px,rx:10,ry:10;
  classDef api fill:#6366f1,stroke:#3730a3,color:#fff,stroke-width:2px,rx:10,ry:10;
  classDef be  fill:#10b981,stroke:#065f46,color:#fff,stroke-width:2px,rx:10,ry:10;
  classDef db  fill:#f59e0b,stroke:#b45309,color:#1f2937,stroke-width:2px,rx:10,ry:10;
  classDef svc fill:#ef4444,stroke:#991b1b,color:#fff,stroke-width:2px,rx:10,ry:10;
```

- Flutter App: UI y consumo de API. Guarda claves/tokens en almacenamiento local (SharedPreferences).
- API REST: Convención JSON; rutas para autenticación, perfiles, trabajos, solicitudes, asignaciones, calificaciones, favoritos, premium y notificaciones.
- Backend: Lógica de negocio, validaciones, generación de PDF, envío de notificaciones.
- PostgreSQL: Persistencia de datos.
- FCM: Entrega de notificaciones push a dispositivos.


### Flujo de datos
1) Flutter envía requests HTTP (JSON) a la API (`/api/...`).
2) Express enruta la solicitud a un Controller, que valida entradas y llama a Services/DB.
3) El Service ejecuta consultas SQL (pg pool) hacia PostgreSQL.
4) El Controller construye la respuesta JSON para la app.
5) Para eventos (alta de solicitud, asignación, etc.), el NotificationService puede enviar notificaciones push por FCM.
6) En procesos premium, el backend genera PDFs de nómina y devuelve el archivo como bytes/stream.


### Frontend (Flutter)
- Lenguaje: Dart
- Consumo de API: `ApiService` y `ApiWrapper`
- Manejo de errores: envoltorios en `ApiWrapper.safeCallWithResult`
- Almacenamiento local: `SharedPreferences` (tokens, flags, configuración básica)
- Notificaciones: SDK de Firebase Messaging (recibe tokens y push)
- Formateo/parseo seguro de tipos: `FormatService.parseInt`, `FormatService.parseDoubleNullable`
- Widgets relevantes:
  - Vistas de contratista y trabajador (perfiles, trabajos, modales de horas y sueldo, listado de empleados, etc.)
  - Deshabilita “Aplicar” si el trabajador ya tiene asignación activa (consulta previa al backend)


### Backend (Node.js + Express)
- Node.js + Express
- CORS habilitado
- Middlewares: `express.json`, `express.urlencoded`
- Manejo de entorno: `dotenv`
- Logging básico a consola
- Endpoint de salud: `GET /api/health` (incluye timeout de DB para Render)
- Manejo global de errores con `errorHandler`

Controladores principales (ejemplos):
- `registerController`: registro de contratistas/trabajadores
- `authController`: login/verify
- `ubicacionController`: ubicación de contratistas/trabajadores y geocercas
- `trabajosCortoPlazoController`, `trabajosLargoPlazoController`: CRUD y consultas
- `solicitudesController`: aplicar a trabajos, gestionar estado y expiración
- `asignacionesController`: asignar, cancelar, finalizar trabajos; calificaciones
- `calificacionesController`: registrar y listar calificaciones
- `favoritosController`: agregar/eliminar y listar favoritos
- `premiumController`: sueldos, horas, gastos extras, generación de nóminas PDF
- `notificacionesController`: registrar token de dispositivo y listar notificaciones

Servicios:
- `DB (pg pool)`: conexión a PostgreSQL
- `NotificationService`: envío de mensajes a FCM (tokens guardados por usuario/dispositivo)
- `PDF (pdfkit u otra librería similar)`: generación de nómina con moneda MXN/USD en montos y totales
- `ErrorHandler`: estandariza respuestas de error


### Base de datos (PostgreSQL)
Entidades clave (resumen de relaciones más usadas por la app):
- Usuarios
  - `contratistas (id_contratista, email, username, nombre, apellido, telefono, fecha_nacimiento, genero, …)`
  - `trabajadores (id_trabajador, email, username, nombre, apellido, telefono, id_categoria, descripcion, …)`
  - `categorias (id_categoria, nombre)`
- Trabajos
  - Corto plazo: `trabajos_corto_plazo_n (id_trabajo_corto, id_contratista, titulo, descripcion, direccion, vacantes, estado, created_at)`
  - Largo plazo: `trabajos_largo_plazo_n (id_trabajo_largo, id_contratista, titulo, descripcion, direccion, presupuesto, moneda_presupuesto, estado, created_at)`
  - Imágenes TCP: `trabajos_corto_plazo_imagenes (id_imagen, id_trabajo_corto, imagen_base64)`
- Operativa
  - `solicitudes_trabajo_n (id_solicitud, id_trabajador, id_contratista, tipo_trabajo, id_trabajo, estado, expira_en, respondido_en, created_at)`
  - `asignaciones_trabajo_n (id_asignacion, id_contratista, id_trabajador, tipo_trabajo, id_trabajo, fecha_asignacion, fecha_cancelacion, estado)`
  - `calificaciones_trabajadores_n (id_calificacion, id_contratista, id_trabajador, id_asignacion, estrellas, comentario, created_at)`
  - `favoritos` o `favoritos_n` (relación contratista ↔ trabajador)
- Premium / Nómina
  - `configuracion_pagos_trabajadores (id_config, id_asignacion, id_trabajo_largo, tipo_periodo, tarifa, moneda, creado_en, actualizado_en)`
  - `horas_laborales (id_hora, id_asignacion, fecha, horas, descripcion, actualizado_en)`
  - `gastos_extras (id_gasto, id_trabajo_largo, id_contratista, fecha_gasto, monto, descripcion)`
  - `nominas_generadas (id_nomina, id_contratista, id_trabajo_largo, periodo_inicio, periodo_fin, generado_en)`
  - `planes_premium, suscripciones_premium_n, metodos_pago_contratista_n, pagos_premium_n`
- Notificaciones
  - `dispositivos_notificaciones (id_dispositivo, email, tipo_usuario, token, plataforma, actualizado_en)`
  - `notificaciones, notificacion_destinatarios`

Notas:
- Las consultas del backend están preparadas para devolver datos en el formato esperado por la app.
- Se han incluido mejoras para evitar errores de tipos (IDs como enteros, coordenadas como doubles).


### Notificaciones Push (Firebase Cloud Messaging)
- Cliente Flutter:
  - Integra Firebase Messaging SDK para recibir notificaciones y obtener el token del dispositivo.
  - Al iniciar sesión, se registra el token mediante `POST /api/notificaciones/token`.
- Backend:
  - `NotificationService` almacena tokens por `email` y `tipo_usuario` y permite enviar notificaciones dirigidas.
  - En eventos relevantes (solicitud recibida, asignación, etc.) se llama a FCM con el token del usuario objetivo.


### Generación de PDF de Nómina
- Módulo en el backend que, a partir de trabajadores asignados, horas, gastos extras, presupuesto y moneda seleccionada (MXN o USD), genera un PDF de resumen:
  - Lista de trabajadores, horas, montos pagados con símbolo de moneda.
  - Gastos extras (total con moneda).
  - Resumen financiero: presupuesto, total pagado, saldo restante (con moneda).
- El controller `premiumController` expone endpoints para generar y descargar los PDFs.


### Variables de entorno (Render)
Configura estas variables en el servicio de Render del backend:
- `DB_HOST` = host de tu PostgreSQL gestionado (Render)
- `DB_PORT` = 5432
- `DB_NAME` = nombre de la BD (p. ej. `obix_db`)
- `DB_USER` = usuario de BD
- `DB_PASSWORD` = contraseña de BD
- `PGSSLMODE` = require
- `JWT_SECRET` = cadena aleatoria segura
- `FIREBASE_CREDENTIALS_BASE64` = credenciales de servicio de Firebase codificadas en Base64 (si las usas para envío server-to-server)
- `NODE_ENV` = production
- `CORS_ORIGIN` = origen permitido (p. ej. `*` o el dominio de tu app web si aplica)
- Otras opcionales usadas por la app (si procede): `SOLICITUD_EXPIRACION_MINUTOS`, `NOTIFICATION_EXPIRATION_MINUTES`, `NOTIFICATIONS_IMAGE_URL`


### Despliegue en Render (Backend y DB)
1) Backend
   - Conectar el repo a Render (Web Service).
   - Build Command: `npm install`
   - Start Command: `node server.js`
   - Región preferida cercana a tu PostgreSQL.
   - Variables de entorno: ver sección anterior.
   - Health check: `GET /api/health`.

2) PostgreSQL
   - Crear instancia administrada de PostgreSQL en Render.
   - Guardar credenciales (host, puerto, db, user, password).
   - Conexión SSL requerida.


### Backup y Restore de la base de datos
- Crear backup (desde máquina local o servidor con acceso):
  - `pg_dump -Fc --no-owner --no-privileges -h <host> -U <user> -d <db> -f obix.dump`
- Restaurar en Render (PowerShell, carpeta `C:\Program Files\PostgreSQL\XX\bin`):
  - `.\pg_restore --verbose --clean --if-exists --no-owner --no-privileges -j 2 --dbname "postgresql://USER:PASSWORD@HOST/DBNAME?sslmode=require" "C:\Ruta\obix.dump"`
  - Si la red es lenta o falla, usa `-j 1`.
- Verificar conexión:
  - `.\psql "postgresql://USER:PASSWORD@HOST/DBNAME?sslmode=require" -c "SELECT now();"`


### Seguridad, logs y salud del servicio
- SSL obligatorio en conexión a PostgreSQL (`PGSSLMODE=require`).
- Manejo de errores centralizado en el backend (estructura JSON consistente).
- `GET /api/health` comprueba estado de servicio y DB con timeout de 3s.
- Render provee logs en tiempo real para diagnosticar errores de despliegue.


### Librerías y para qué se usan
Frontend (Flutter/Dart):
- `http`: consumo de API HTTP.
- `shared_preferences`: almacenamiento local de claves y flags.
- `firebase_messaging`: recepción de notificaciones push y obtención de tokens.
- Utilidades propias: `FormatService` para parseo seguro de tipos (int/double).

Backend (Node.js/Express):
- `express`: framework HTTP para rutas y middlewares.
- `cors`: habilitar CORS.
- `dotenv`: variables de entorno.
- `pg` / `pg-pool`: conexión y pool a PostgreSQL.
- `pdfkit` (o similar): generación de PDF de nómina.
- (Opcional) `firebase-admin`: enviar notificaciones a FCM desde el servidor.

Base de datos (PostgreSQL):
- Índices y claves foráneas para integridad y rendimiento.
- Algunas tablas incluyen columnas de auditoría simples (`created_at`, `actualizado_en`).


### Cómo correr localmente (resumen)
1) Variables de entorno en `.env` (mismas que en Render, apuntando a tu DB local/remota).
2) Backend:
   - `npm install`
   - `node server.js`
   - Probar: `GET http://localhost:10000/api/health`
3) Flutter:
   - Configurar `lib/services/config_service.dart` con la URL del backend (por ejemplo, `http://10.0.2.2:10000/api` para emulador Android o la URL de Render).
   - Ejecutar la app en dispositivo/emulador.


### Notas finales
- Evita cambios de esquema en caliente sin considerar el impacto en endpoints existentes.
- Ante errores de tipo en Flutter (String ↔ int/double), valida que el backend devuelva tipos nativos correctos y sigue usando `FormatService`.
- El PDF de nómina incluye símbolos de moneda (MXN/USD) tanto en filas de trabajadores como en totales.


— Equipo OBIX

# Integradora – Documentación Técnica

Este README resume la arquitectura, componentes clave y decisiones de diseño del proyecto Integradora. Está pensado como guía de estudio para responder preguntas técnicas, justificar la estructura actual y planear futuras versiones.

---

## Panorama General

- **Arquitectura cliente-servidor:** Flutter (cliente) consume una API REST Node.js/Express (servidor). Esta separación permite desplegar cada capa por separado y escalar servicios sin recompilar la app.
- **Comunicación:** HTTP + JSON sobre rutas `/api/*`. El frontend centraliza las peticiones en `lib/services/api_service.dart`.
- **Autenticación:** JWT emitido por el backend; se guarda en `shared_preferences` para adjuntarlo en cada petición.
- **Base de datos:** PostgreSQL. La estructura está normalizada hasta 4FN para evitar duplicidad y mantener la consistencia a largo plazo. Los scripts viven en `backend/scripts/`.

---

## Frontend (Flutter)

- **Estructura:**  
  - `lib/views/` pantallas y widgets.  
  - `lib/models/` mapea el JSON del backend (`TrabajoLargoModel`, `TrabajoCortoModel`, `AsignacionTrabajoModel`, etc.).  
  - `lib/services/` consumo de API, almacenamiento local y utilidades.
- **Funcionalidades destacadas:**  
  - Registro y visualización de trabajos corto/largo plazo.  
  - Geolocalización con `geolocator` y apertura de Google Maps.  
  - Captura de imágenes con `image_picker` (Base64).  
  - Manejo de notificaciones push con Firebase Messaging.
- **Patrón:** MVC por módulos; cada pantalla obtiene datos mediante servicios y los presenta con widgets reutilizables.

---

## Backend (Node.js/Express)

- **Entrada principal:** `backend/server.js` monta middlewares (CORS, JSON 50 MB) y registra rutas por dominio.
- **Rutas y controladores:**  
  - `routes/*.js` → `controllers/*.js`. Por ejemplo `asignacionesRoutes` delega en `asignacionesController`.  
  - Uso intensivo de transacciones (`BEGIN/COMMIT/ROLLBACK`) para mantener la integridad en asignaciones, cancelaciones y calificaciones.
- **Servicios auxiliares:**  
  - `services/notificationService.js`: creación y envío de notificaciones.  
  - `services/firebaseService.js`: wrapper de Firebase Admin para FCM.  
  - `services/solicitudesService.js`, `utils/emailUtils.js`, etc.

---

## Base de Datos

> El diagrama entidad-relación (ver imagen adjunta en `docs/diagrama-er.png`) muestra las tablas actuales. Falta únicamente la futura tabla de horas premium.

- **Tablas principales:**  
  - `trabajadores`, `contratistas`: datos personales, ubicación, calificación promedio.  
  - `solicitudes_trabajo`: historial de solicitudes con estados (`pendiente`, `aceptada`, `rechazada`, `expirada`, `cancelada`).  
  - `trabajos_largo_plazo`, `trabajos_corto_plazo`, `trabajos_corto_plazo_imagenes`: ofertas de trabajo según duración.  
  - `asignaciones_trabajo`: vincula contratista ↔ trabajador ↔ trabajo, con control de estado y fechas.  
  - `calificaciones_trabajadores`: reseñas posteriores a cada asignación.  
  - `notificaciones_usuario`: histórico de notificaciones creadas.  
  - `dispositivos_notificaciones`: tokens FCM por usuario y tipo.  
  - `favoritos`, `categorias`: soporte para catálogos y relaciones auxiliares.
- **Normalización:**  
  - No existen atributos multivaluados; por ejemplo, imágenes de trabajos cortos en tabla separada.  
  - Dependencias funcionales mantenidas por claves foráneas (`email_trabajador`, `id_trabajo_largo`, etc.).  
  - Los atributos derivados (ej. `calificacion_promedio`) se actualizan con triggers controlados desde el backend para evitar redundancias sincrónicas.  
  - Preparado para 4FN: en tablas como `dispositivos_notificaciones` se separan cada token/plataforma para un email, evitando grupos repetidos.
- **Próxima versión:** se añadirá `horas_trabajadas` (para usuarios premium) relacionada con `asignaciones_trabajo`. La normalización facilita incluir esta tabla sin romper integridad.

---

## Flujo de Notificaciones Push

1. **Registro de dispositivos**  
   - `notificationService.registrarTokenDispositivo` guarda token FCM, email y tipo de usuario en `dispositivos_notificaciones`.  
   - Se ejecuta desde el frontend al iniciar sesión.

2. **Creación de notificaciones**  
   - `notificationService.crearNotificacion` inserta en `notificaciones_usuario` el título, cuerpo, tipo y payload JSON.  
   - Se reutiliza en todos los caso de uso (cancelaciones, calificaciones, etc.).

3. **Envío push**  
   - `sendPushNotification` (Firebase Admin) toma los tokens del destinatario y envía el mensaje con los datos extra (`data`) para que la app abra la vista correspondiente.

4. **Casos específicos**  
   - **Cancelación iniciada por trabajador:**  
     - `asignacionesController.cancelarAsignacion` detecta `iniciadoPorTrabajador`, crea notificación `solicitud_cancelada` para el contratista y envía push.  
   - **Cancelación iniciada por contratista:**  
     - Misma función, rama `else`, genera notificación `desvinculacion` para el trabajador.  
   - **Registro de calificación:**  
     - `calificacionesController.registrarCalificacion` calcula el nuevo promedio, actualiza `trabajadores.calificacion_promedio` y llama `notificarCalificacionTrabajador`, que emite la notificación `calificacion_trabajador`.

---

## Integración Frontend ↔ Backend

- El frontend encapsula las llamadas al backend en `ApiService`, lo que facilita cambiar la URL base o añadir headers sin tocar cada pantalla.
- Cada controlador retorna JSON consistente (`{ success, data, message }`), permitiendo manejo homogéneo de errores.
- Para ambientes:  
  - Desarrollo local usa IP configurable documentada en `CONFIGURACION_IP_AUTOMATICA.md`.  
  - Producción puede apuntar a Render u otra nube simplemente cambiando la URL base.

---

## Flujos Clave

- **Publicar trabajo (contratista):** formulario → `ApiService` → `trabajos*Corto/Largo*Controller` → inserción en BD → respuesta con detalles.  
- **Contratar trabajador:** pantalla `WorkerCard` → `ApiService.asignarTrabajo` → transacción que inserta en `asignaciones_trabajo`, ajusta vacantes y disponibilidad → posible notificación al trabajador.  
- **Cancelar asignación:** `ApiService.cancelarAsignacion` → rollback de vacantes y disponibilidad → creación de notificación y push según quién cancele.  
- **Calificar trabajador:** formulario en la notificación → `calificacionesController.registrarCalificacion` → inserción + recomputo de promedio + notificación al trabajador.

---

## Preparación para Futuras Versiones

- **Horas premium:** se añadirá tabla `horas_trabajadas` (id, id_asignacion, fecha, horas, comentarios). Al estar la asignación y el trabajador separados, basta con una FK a `asignaciones_trabajo`.
- **Escalabilidad:** servicios desacoplados (notificaciones, email) se pueden migrar a colas o microservicios sin reescribir la lógica central.
- **Testing y documentación:** recomendable agregar pruebas de integración para asignaciones y calificaciones, y documentación OpenAPI para facilitar nuevos clientes.

---

## Comandos Útiles

```bash
# Backend
cd backend
npm install
npm run dev     # servidor Express con nodemon

# Base de datos
# Ejecutar scripts en orden según README de scripts (ej. create_tables.sql, create_asignaciones_tables.sql, etc.)

# Frontend Flutter
flutter pub get
flutter run     # emulador o dispositivo conectado
```

Configura las variables de entorno (`.env`) con credenciales de PostgreSQL, claves JWT y parámetros de Firebase (`firebase-service-account.json`).

---

## Recursos de Estudio

- Repasa los controladores `asignacionesController.js` y `calificacionesController.js` para explicar los escenarios de negocio.  
- Consulta `backend/scripts/*.sql` junto con el diagrama ER para justificar la normalización y relaciones.  
- Desde Flutter, sigue el flujo `home_view.dart` → `worker_card.dart` → `assign_modal_work.dart` para explicar la experiencia del contratista.  
- Practica demostraciones manuales: publicar trabajo, asignar, cancelar y calificar para corroborar las notificaciones en ambos roles.

---

Con esta documentación podrás defender la arquitectura, argumentar la normalización de la base de datos y explicar cómo se integran notificaciones, seguridad y flujos principales. Para futuras ampliaciones (como la tabla de horas premium) la estructura actual ya contempla las relaciones necesarias.
