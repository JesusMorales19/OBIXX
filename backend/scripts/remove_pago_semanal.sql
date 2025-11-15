-- Eliminar la columna pago_semanal de trabajos_largo_plazo

ALTER TABLE trabajos_largo_plazo 
DROP COLUMN IF EXISTS pago_semanal;

-- Eliminar el constraint de validación de pago (si existe)
ALTER TABLE trabajos_largo_plazo 
DROP CONSTRAINT IF EXISTS check_pago_positivo;

