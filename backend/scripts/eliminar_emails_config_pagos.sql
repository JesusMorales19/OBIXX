-- ================================================
-- SCRIPT PARA ELIMINAR CAMPOS REDUNDANTES
-- email_trabajador y email_contratista de configuracion_pagos_trabajadores
-- ================================================
-- Estos campos son redundantes porque ya están en asignaciones_trabajo
-- Se pueden obtener mediante JOIN: id_asignacion → asignaciones_trabajo
-- ================================================

DO $$
BEGIN
    -- Eliminar constraint FK de email_trabajador si existe
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_config_pago_trabajador'
    ) THEN
        ALTER TABLE configuracion_pagos_trabajadores 
        DROP CONSTRAINT fk_config_pago_trabajador;
        RAISE NOTICE '✅ Constraint fk_config_pago_trabajador eliminado';
    END IF;

    -- Eliminar constraint FK de email_contratista si existe
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_config_pago_contratista'
    ) THEN
        ALTER TABLE configuracion_pagos_trabajadores 
        DROP CONSTRAINT fk_config_pago_contratista;
        RAISE NOTICE '✅ Constraint fk_config_pago_contratista eliminado';
    END IF;

    -- Eliminar índice de email_trabajador si existe
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'configuracion_pagos_trabajadores' 
        AND indexname = 'idx_config_pagos_trabajador'
    ) THEN
        DROP INDEX IF EXISTS idx_config_pagos_trabajador;
        RAISE NOTICE '✅ Índice idx_config_pagos_trabajador eliminado';
    END IF;

    -- Eliminar columna email_trabajador
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_pagos_trabajadores' 
        AND column_name = 'email_trabajador'
    ) THEN
        ALTER TABLE configuracion_pagos_trabajadores 
        DROP COLUMN email_trabajador;
        RAISE NOTICE '✅ Columna email_trabajador eliminada de configuracion_pagos_trabajadores';
    END IF;

    -- Eliminar columna email_contratista
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_pagos_trabajadores' 
        AND column_name = 'email_contratista'
    ) THEN
        ALTER TABLE configuracion_pagos_trabajadores 
        DROP COLUMN email_contratista;
        RAISE NOTICE '✅ Columna email_contratista eliminada de configuracion_pagos_trabajadores';
    END IF;

    -- NO eliminar columna moneda - ahora se usa para MXN y USD
    -- El campo moneda se mantiene para soportar múltiples monedas

    RAISE NOTICE '✅ Eliminación de campos redundantes completada';
END $$;

-- ================================================
-- VERIFICAR QUE LAS CONSULTAS SIGAN FUNCIONANDO
-- ================================================
-- Las consultas ahora deben usar JOINs:
-- 
-- SELECT c.*, a.email_trabajador, a.email_contratista
-- FROM configuracion_pagos_trabajadores c
-- INNER JOIN asignaciones_trabajo a ON c.id_asignacion = a.id_asignacion
-- 
-- ================================================

