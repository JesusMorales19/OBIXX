-- ================================================
-- SCRIPT PARA ELIMINAR CAMPOS ANTIGUOS DE PREMIUM
-- Si existen campos es_premium, fecha_inicio_premium, fecha_fin_premium
-- en la tabla contratistas, este script los elimina
-- ================================================
-- IMPORTANTE: Ejecutar solo si estás seguro de que no hay datos importantes
-- en estos campos. Los nuevos campos usan tablas normalizadas (4FN).
-- ================================================

-- Verificar si existen los campos antes de eliminarlos
DO $$
BEGIN
    -- Eliminar columna es_premium si existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' AND column_name = 'es_premium'
    ) THEN
        ALTER TABLE contratistas DROP COLUMN IF EXISTS es_premium;
        RAISE NOTICE 'Columna es_premium eliminada';
    END IF;

    -- Eliminar columna fecha_inicio_premium si existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' AND column_name = 'fecha_inicio_premium'
    ) THEN
        ALTER TABLE contratistas DROP COLUMN IF EXISTS fecha_inicio_premium;
        RAISE NOTICE 'Columna fecha_inicio_premium eliminada';
    END IF;

    -- Eliminar columna fecha_fin_premium si existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' AND column_name = 'fecha_fin_premium'
    ) THEN
        ALTER TABLE contratistas DROP COLUMN IF EXISTS fecha_fin_premium;
        RAISE NOTICE 'Columna fecha_fin_premium eliminada';
    END IF;
    
    RAISE NOTICE 'Limpieza de campos antiguos completada';
END $$;

-- ================================================
-- FIN DEL SCRIPT DE LIMPIEZA
-- ================================================

