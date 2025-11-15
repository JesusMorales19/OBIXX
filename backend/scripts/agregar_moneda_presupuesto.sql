-- ================================================
-- AGREGAR CAMPO moneda A trabajos_largo_plazo
-- Para el presupuesto del trabajo
-- ================================================

DO $$
BEGIN
    -- Agregar columna moneda si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trabajos_largo_plazo' 
        AND column_name = 'moneda_presupuesto'
    ) THEN
        ALTER TABLE trabajos_largo_plazo 
        ADD COLUMN moneda_presupuesto VARCHAR(3) DEFAULT 'MXN' CHECK (moneda_presupuesto IN ('MXN', 'USD'));
        
        RAISE NOTICE '✅ Columna moneda_presupuesto agregada a trabajos_largo_plazo';
    ELSE
        RAISE NOTICE '⚠️ La columna moneda_presupuesto ya existe en trabajos_largo_plazo';
    END IF;
END $$;

-- Actualizar registros existentes a MXN si son NULL
UPDATE trabajos_largo_plazo 
SET moneda_presupuesto = 'MXN' 
WHERE moneda_presupuesto IS NULL;

-- Comentario
COMMENT ON COLUMN trabajos_largo_plazo.moneda_presupuesto IS 'Moneda del presupuesto: MXN o USD';

