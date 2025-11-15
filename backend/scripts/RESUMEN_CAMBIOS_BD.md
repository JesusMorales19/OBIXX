# RESUMEN DE CAMBIOS EN LA BASE DE DATOS

## 📋 TABLAS QUE FALTAN (8 nuevas tablas)

### 1. **planes_premium**
- `id_plan` (SERIAL PRIMARY KEY)
- `nombre` (VARCHAR(50) UNIQUE)
- `periodicidad` (VARCHAR(20) - 'mensual' o 'anual')
- `precio` (NUMERIC(10,2))
- `descripcion` (TEXT)
- `activo` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### 2. **metodos_pago_contratista**
- `id_metodo` (SERIAL PRIMARY KEY)
- `email_contratista` (VARCHAR(100) FK → contratistas.email)
- `alias` (VARCHAR(50))
- `marca` (VARCHAR(30))
- `ultimos4` (VARCHAR(4))
- `token_pasarela` (TEXT)
- `es_predeterminado` (BOOLEAN)
- `activo` (BOOLEAN)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

### 3. **suscripciones_premium**
- `id_suscripcion` (SERIAL PRIMARY KEY)
- `email_contratista` (VARCHAR(100) FK → contratistas.email)
- `id_plan` (INTEGER FK → planes_premium.id_plan)
- `id_metodo_pago` (INTEGER FK → metodos_pago_contratista.id_metodo)
- `fecha_inicio` (TIMESTAMP)
- `fecha_fin` (TIMESTAMP)
- `estado` (VARCHAR(20) - 'activa', 'vencida', 'cancelada', 'suspendida')
- `auto_renovacion` (BOOLEAN)
- `fecha_cancelacion` (TIMESTAMP)
- `motivo_cancelacion` (TEXT)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

### 4. **pagos_premium**
- `id_pago` (SERIAL PRIMARY KEY)
- `id_suscripcion` (INTEGER FK → suscripciones_premium.id_suscripcion)
- `id_metodo_pago` (INTEGER FK → metodos_pago_contratista.id_metodo)
- `monto` (NUMERIC(10,2))
- `moneda` (VARCHAR(3))
- `referencia_pasarela` (VARCHAR(255))
- `status` (VARCHAR(20) - 'pendiente', 'completado', 'fallido', 'reembolsado')
- `payload_pasarela` (JSONB)
- `pagado_en` (TIMESTAMP)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

### 5. **horas_laborales**
- `id_registro` (SERIAL PRIMARY KEY)
- `id_asignacion` (INTEGER FK → asignaciones_trabajo.id_asignacion)
- `email_trabajador` (VARCHAR(100) FK → trabajadores.email)
- `email_contratista` (VARCHAR(100) FK → contratistas.email)
- `fecha` (DATE)
- `horas` (NUMERIC(5,2))
- `minutos` (NUMERIC(5,2))
- `nota` (TEXT)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)
- UNIQUE: (id_asignacion, email_trabajador, fecha)

### 6. **configuracion_pagos_trabajadores**
- `id_configuracion` (SERIAL PRIMARY KEY)
- `id_asignacion` (INTEGER FK → asignaciones_trabajo.id_asignacion)
- `id_trabajo_largo` (INTEGER FK → trabajos_largo_plazo.id_trabajo_largo)
- `email_trabajador` (VARCHAR(100) FK → trabajadores.email)
- `email_contratista` (VARCHAR(100) FK → contratistas.email)
- `tipo_periodo` (VARCHAR(20) - 'semanal' o 'quincenal')
- `monto_periodo` (NUMERIC(10,2))
- `moneda` (VARCHAR(3))
- `horas_requeridas_periodo` (NUMERIC(5,2))
- `activo` (BOOLEAN)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)
- UNIQUE: (id_asignacion)

### 7. **nominas_generadas**
- `id_nomina` (SERIAL PRIMARY KEY)
- `id_trabajo_largo` (INTEGER FK → trabajos_largo_plazo.id_trabajo_largo)
- `email_contratista` (VARCHAR(100) FK → contratistas.email)
- `periodo_inicio` (DATE)
- `periodo_fin` (DATE)
- `presupuesto_total` (NUMERIC(12,2))
- `total_pagado_trabajadores` (NUMERIC(10,2))
- `total_gastos_extras` (NUMERIC(10,2)) ⚠️ **CAMPO AGREGADO**
- `saldo_restante` (NUMERIC(12,2))
- `moneda` (VARCHAR(3))
- `detalle_trabajadores` (JSONB)
- `detalle_gastos_extras` (JSONB) ⚠️ **CAMPO AGREGADO**
- `archivo_url` (TEXT)
- `archivo_base64` (TEXT)
- `generado_en` (TIMESTAMP)
- `descargado` (BOOLEAN)
- `descargado_en` (TIMESTAMP)

### 8. **gastos_extras**
- `id_gasto_extra` (SERIAL PRIMARY KEY)
- `id_trabajo_largo` (INTEGER FK → trabajos_largo_plazo.id_trabajo_largo)
- `email_contratista` (VARCHAR(100) FK → contratistas.email)
- `fecha_gasto` (DATE)
- `monto` (NUMERIC(10,2))
- `descripcion` (TEXT)
- `creado_en` (TIMESTAMP)

---

## 🔄 TABLAS A MODIFICAR

### **contratistas**
**CAMPOS A AGREGAR:**
- `id_suscripcion_activa` (INTEGER FK → suscripciones_premium.id_suscripcion)
- `id_metodo_pago_preferido` (INTEGER FK → metodos_pago_contratista.id_metodo)
- `auto_renovacion_activa` (BOOLEAN DEFAULT false)

**CAMPOS A ELIMINAR (si existen):**
- ❌ `es_premium` (BOOLEAN) - Ya no se usa, se verifica en suscripciones_premium
- ❌ `fecha_inicio_premium` (TIMESTAMP) - Ya no se usa, está en suscripciones_premium
- ❌ `fecha_fin_premium` (TIMESTAMP) - Ya no se usa, está en suscripciones_premium

### **trabajos_largo_plazo**
**CAMPOS A AGREGAR:**
- `presupuesto` (NUMERIC(12,2) NULL) - Solo para contratistas premium

---

## 📊 RELACIONES NUEVAS

1. **contratistas** → **suscripciones_premium** (1:N)
2. **contratistas** → **metodos_pago_contratista** (1:N)
3. **planes_premium** → **suscripciones_premium** (1:N)
4. **metodos_pago_contratista** → **suscripciones_premium** (1:N)
5. **suscripciones_premium** → **pagos_premium** (1:N)
6. **asignaciones_trabajo** → **horas_laborales** (1:N)
7. **asignaciones_trabajo** → **configuracion_pagos_trabajadores** (1:1)
8. **trabajos_largo_plazo** → **nominas_generadas** (1:N)
9. **trabajos_largo_plazo** → **gastos_extras** (1:N)

---

## ✅ TABLAS QUE YA EXISTEN (No modificar)

- ✅ categorias
- ✅ trabajadores
- ✅ contratistas (solo agregar campos)
- ✅ favoritos
- ✅ solicitudes_trabajo
- ✅ dispositivos_notificaciones
- ✅ asignaciones_trabajo
- ✅ trabajos_largo_plazo (solo agregar campo presupuesto)
- ✅ trabajos_corto_plazo
- ✅ trabajos_corto_plazo_imagenes
- ✅ calificaciones_trabajadores
- ✅ notificaciones_usuario

---

## 📝 NOTAS IMPORTANTES

1. **Normalización 4FN**: Todas las nuevas tablas siguen la 4ta Forma Normal
2. **Presupuesto**: El campo `presupuesto` en `trabajos_largo_plazo` es NULL por defecto y solo se asigna cuando el contratista tiene premium activo
3. **Gastos Extras**: Se agregaron campos `total_gastos_extras` y `detalle_gastos_extras` a `nominas_generadas` para incluir gastos adicionales en las nóminas
4. **Cancelación**: La tabla `suscripciones_premium` tiene campo `fecha_cancelacion` para registrar cuando se cancela una suscripción

---

## 🚀 SCRIPTS A EJECUTAR

1. `create_premium_final.sql` - Crea todas las tablas premium
2. `add_gastos_extras.sql` - Agrega tabla gastos_extras y modifica nominas_generadas

