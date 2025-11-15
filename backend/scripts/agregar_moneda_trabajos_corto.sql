-- ================================================
-- AGREGAR CAMPO moneda A trabajos_corto_plazo
-- ================================================

DO $$
BEGIN
    -- Agregar columna moneda si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trabajos_corto_plazo' 
        AND column_name = 'moneda'
    ) THEN
        ALTER TABLE trabajos_corto_plazo 
        ADD COLUMN moneda VARCHAR(3) DEFAULT 'MXN' CHECK (moneda IN ('MXN', 'USD'));
        
        RAISE NOTICE '✅ Columna moneda agregada a trabajos_corto_plazo';
    ELSE
        RAISE NOTICE '⚠️ La columna moneda ya existe en trabajos_corto_plazo';
    END IF;
END $$;

-- Actualizar registros existentes a MXN si son NULL
UPDATE trabajos_corto_plazo 
SET moneda = 'MXN' 
WHERE moneda IS NULL;

-- Comentario
COMMENT ON COLUMN trabajos_corto_plazo.moneda IS 'Moneda del rango de pago: MXN o USD';

