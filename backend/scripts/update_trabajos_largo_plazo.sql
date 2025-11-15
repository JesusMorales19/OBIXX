-- Modificar tabla trabajos_largo_plazo
-- Quitar ubicacion_geohash y agregar latitud/longitud
-- Cambiar id_contratista por email_contratista

-- 1. Eliminar columna ubicacion_geohash
ALTER TABLE trabajos_largo_plazo 
DROP COLUMN IF EXISTS ubicacion_geohash;

-- 2. Cambiar id_contratista por email_contratista (si existe)
-- Primero eliminar el constraint de foreign key antiguo
ALTER TABLE trabajos_largo_plazo 
DROP CONSTRAINT IF EXISTS fk_trabajos_largo_contratista;

-- Eliminar la columna id_contratista si existe
ALTER TABLE trabajos_largo_plazo 
DROP COLUMN IF EXISTS id_contratista;

-- Agregar email_contratista
ALTER TABLE trabajos_largo_plazo 
ADD COLUMN IF NOT EXISTS email_contratista VARCHAR(100);

-- Agregar el nuevo constraint de foreign key
ALTER TABLE trabajos_largo_plazo 
ADD CONSTRAINT fk_trabajos_largo_contratista 
  FOREIGN KEY (email_contratista) 
  REFERENCES contratistas(email) 
  ON DELETE CASCADE;

-- 3. Agregar columnas de latitud y longitud
ALTER TABLE trabajos_largo_plazo 
ADD COLUMN IF NOT EXISTS latitud NUMERIC(10, 8),
ADD COLUMN IF NOT EXISTS longitud NUMERIC(11, 8),
ADD COLUMN IF NOT EXISTS direccion TEXT;

-- 4. Eliminar pago_semanal (ya no se usa)
ALTER TABLE trabajos_largo_plazo 
DROP COLUMN IF EXISTS pago_semanal;

-- 5. Eliminar constraint de pago (si existe)
ALTER TABLE trabajos_largo_plazo 
DROP CONSTRAINT IF EXISTS check_pago_positivo;

-- 6. Crear índice para búsquedas por ubicación
CREATE INDEX IF NOT EXISTS idx_trabajos_largo_ubicacion ON trabajos_largo_plazo(latitud, longitud);

-- 4. Agregar comentarios
COMMENT ON COLUMN trabajos_largo_plazo.latitud IS 'Latitud de la ubicación del trabajo';
COMMENT ON COLUMN trabajos_largo_plazo.longitud IS 'Longitud de la ubicación del trabajo';
COMMENT ON COLUMN trabajos_largo_plazo.direccion IS 'Dirección legible del trabajo (opcional)';

