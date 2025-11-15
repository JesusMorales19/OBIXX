# 🗑️ CAMPOS Y TABLAS REDUNDANTES PARA ELIMINAR

## ❌ CAMPOS A ELIMINAR (Redundantes o No Utilizados)

### 1. **nominas_generadas**
**Campos a eliminar:**
- ❌ `archivo_url` (TEXT) - **NO SE USA**. Solo se usa `archivo_base64`
- ❌ `descargado` (BOOLEAN) - **NO SE USA** en ningún lugar del código
- ❌ `descargado_en` (TIMESTAMP) - **NO SE USA** en ningún lugar del código
- ⚠️ `moneda` (VARCHAR(3)) - **Siempre es 'MXN'**, podría eliminarse o dejarse como DEFAULT

**Razón:** El PDF se guarda solo en `archivo_base64`, no se usa URL ni tracking de descarga.

---

### 2. **configuracion_pagos_trabajadores**
**Campos redundantes (ya están en otras tablas):**
- ⚠️ `email_trabajador` (VARCHAR(100)) - **REDUNDANTE**. Ya está en `asignaciones_trabajo`
- ⚠️ `email_contratista` (VARCHAR(100)) - **REDUNDANTE**. Ya está en `trabajos_largo_plazo` y `asignaciones_trabajo`
- ⚠️ `moneda` (VARCHAR(3)) - **Siempre es 'MXN'**, podría eliminarse

**Razón:** Se puede obtener de las relaciones FK (`id_asignacion` → `asignaciones_trabajo` → `email_trabajador` y `email_contratista`)

---

### 3. **horas_laborales**
**Campos redundantes (ya están en otras tablas):**
- ⚠️ `email_trabajador` (VARCHAR(100)) - **REDUNDANTE**. Ya está en `asignaciones_trabajo`
- ⚠️ `email_contratista` (VARCHAR(100)) - **REDUNDANTE**. Ya está en `asignaciones_trabajo`

**Razón:** Se puede obtener de la relación FK (`id_asignacion` → `asignaciones_trabajo` → ambos emails)

**NOTA:** Estos campos se mantienen para mejorar rendimiento en consultas, pero técnicamente son redundantes.

---

### 4. **pagos_premium**
**Campos a considerar:**
- ⚠️ `moneda` (VARCHAR(3)) - **Siempre es 'MXN'**, podría eliminarse o dejarse como DEFAULT

---

### 5. **gastos_extras**
**Campos faltantes (para consistencia):**
- ✅ Agregar `moneda` (VARCHAR(3) DEFAULT 'MXN') - Para consistencia con otras tablas

---

### 6. **trabajadores / contratistas**
**Campos a revisar:**
- ⚠️ `username` (VARCHAR(100)) - **Se usa para login**, pero podría ser redundante si siempre se usa email
- ⚠️ `fecha_nacimiento` (VARCHAR(100)) - **TIPO INCORRECTO**. Debería ser `DATE`, no `VARCHAR`
- ⚠️ `genero` (VARCHAR(20)) - Se usa pero podría ser opcional (NULL permitido)

**Recomendación:** 
- Mantener `username` si se usa para login alternativo
- Cambiar `fecha_nacimiento` de VARCHAR a DATE
- `genero` puede quedarse como está

---

### 7. **solicitudes_trabajo**
**Campos a revisar:**
- ⚠️ `expira_en` (TIMESTAMP) - **Verificar si se usa**. Si no se usa, eliminar

---

## 📊 RESUMEN DE ELIMINACIONES RECOMENDADAS

### **ELIMINAR COMPLETAMENTE:**

1. **nominas_generadas:**
   ```sql
   ALTER TABLE nominas_generadas 
   DROP COLUMN IF EXISTS archivo_url,
   DROP COLUMN IF EXISTS descargado,
   DROP COLUMN IF EXISTS descargado_en;
   ```

2. **configuracion_pagos_trabajadores:**
   ```sql
   ALTER TABLE configuracion_pagos_trabajadores 
   DROP COLUMN IF EXISTS email_trabajador,
   DROP COLUMN IF EXISTS email_contratista,
   DROP COLUMN IF EXISTS moneda;  -- Si siempre es MXN
   ```

3. **horas_laborales:**
   ```sql
   -- OPCIONAL: Eliminar si se quiere normalizar completamente
   -- Pero se recomienda mantenerlos para rendimiento
   ALTER TABLE horas_laborales 
   DROP COLUMN IF EXISTS email_trabajador,
   DROP COLUMN IF EXISTS email_contratista;
   ```

### **CAMBIAR TIPO DE DATO:**

1. **trabajadores / contratistas:**
   ```sql
   -- Cambiar fecha_nacimiento de VARCHAR a DATE
   ALTER TABLE trabajadores 
   ALTER COLUMN fecha_nacimiento TYPE DATE USING fecha_nacimiento::DATE;
   
   ALTER TABLE contratistas 
   ALTER COLUMN fecha_nacimiento TYPE DATE USING fecha_nacimiento::DATE;
   ```

### **AGREGAR (para consistencia):**

1. **gastos_extras:**
   ```sql
   ALTER TABLE gastos_extras 
   ADD COLUMN IF NOT EXISTS moneda VARCHAR(3) DEFAULT 'MXN';
   ```

---

## ⚠️ ADVERTENCIAS

1. **Antes de eliminar campos redundantes en `horas_laborales` y `configuracion_pagos_trabajadores`:**
   - Verificar que las consultas usen JOINs correctamente
   - Estos campos pueden mejorar el rendimiento (denormalización intencional)
   - **Recomendación:** Mantenerlos para rendimiento, pero documentar que son redundantes

2. **Antes de eliminar `moneda`:**
   - Verificar si en el futuro se necesitará soporte multi-moneda
   - Si siempre será MXN, se puede eliminar o dejar como DEFAULT

3. **Antes de cambiar `fecha_nacimiento`:**
   - Verificar que todos los datos existentes sean convertibles a DATE
   - Hacer backup antes de la conversión

---

## ✅ CAMPOS QUE SÍ SE USAN (NO ELIMINAR)

- ✅ `username` - Se usa para login alternativo
- ✅ `genero` - Se usa en perfiles
- ✅ `descripcion` (trabajadores) - Se usa en perfiles
- ✅ `alias` (metodos_pago_contratista) - Se usa para mostrar nombre de tarjeta
- ✅ `token_pasarela` (metodos_pago_contratista) - Se usa (aunque sea simulado)
- ✅ `archivo_base64` (nominas_generadas) - **SÍ SE USA**, contiene el PDF

---

## 🎯 PRIORIDAD DE ELIMINACIÓN

### **ALTA PRIORIDAD (Eliminar definitivamente):**
1. `nominas_generadas.archivo_url` ❌
2. `nominas_generadas.descargado` ❌
3. `nominas_generadas.descargado_en` ❌

### **MEDIA PRIORIDAD (Revisar uso):**
1. `configuracion_pagos_trabajadores.email_trabajador` ⚠️
2. `configuracion_pagos_trabajadores.email_contratista` ⚠️
3. `horas_laborales.email_trabajador` ⚠️ (mantener para rendimiento)
4. `horas_laborales.email_contratista` ⚠️ (mantener para rendimiento)

### **BAJA PRIORIDAD (Optimización futura):**
1. Campos `moneda` que siempre son 'MXN' ⚠️
2. Cambiar `fecha_nacimiento` de VARCHAR a DATE ⚠️

