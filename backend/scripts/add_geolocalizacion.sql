-- Script para agregar columnas de geolocalización a las tablas

-- Agregar columnas de ubicación a contratistas
ALTER TABLE contratistas 
ADD COLUMN IF NOT EXISTS latitud NUMERIC(10, 8),
ADD COLUMN IF NOT EXISTS longitud NUMERIC(11, 8),
ADD COLUMN IF NOT EXISTS ubicacion_actualizada TIMESTAMP;

-- Agregar columnas de ubicación a trabajadores
ALTER TABLE trabajadores 
ADD COLUMN IF NOT EXISTS latitud NUMERIC(10, 8),
ADD COLUMN IF NOT EXISTS longitud NUMERIC(11, 8),
ADD COLUMN IF NOT EXISTS ubicacion_actualizada TIMESTAMP;

-- Crear índices para búsquedas de ubicación más rápidas
CREATE INDEX IF NOT EXISTS idx_contratistas_ubicacion ON contratistas(latitud, longitud);
CREATE INDEX IF NOT EXISTS idx_trabajadores_ubicacion ON trabajadores(latitud, longitud);

-- Comentarios sobre las columnas
-- latitud: Coordenada de latitud (-90 a 90)
-- longitud: Coordenada de longitud (-180 a 180)
-- ubicacion_actualizada: Timestamp de la última actualización de ubicación

