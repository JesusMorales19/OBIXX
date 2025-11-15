-- Script para agregar columna de foto a las tablas

-- Agregar columna de foto a contratistas
ALTER TABLE contratistas 
ADD COLUMN IF NOT EXISTS foto TEXT;

-- Agregar columna de foto a trabajadores
ALTER TABLE trabajadores 
ADD COLUMN IF NOT EXISTS foto TEXT;

-- Comentario: La columna foto almacenará la imagen en formato base64

