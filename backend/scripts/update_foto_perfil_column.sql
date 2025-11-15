-- Script para actualizar la columna foto_perfil a TEXT (sin límite de tamaño)
-- Esto permite almacenar imágenes en Base64 que pueden ser muy grandes

-- Actualizar tabla contratistas
ALTER TABLE contratistas 
ALTER COLUMN foto_perfil TYPE TEXT;

-- Actualizar tabla trabajadores
ALTER TABLE trabajadores 
ALTER COLUMN foto_perfil TYPE TEXT;

-- Si la columna no existe, crearla como TEXT
-- (Ejecutar solo si la columna no existe)
-- ALTER TABLE contratistas ADD COLUMN IF NOT EXISTS foto_perfil TEXT;
-- ALTER TABLE trabajadores ADD COLUMN IF NOT EXISTS foto_perfil TEXT;

