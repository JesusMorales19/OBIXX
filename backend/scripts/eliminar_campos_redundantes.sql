-- ================================================
-- SCRIPT PARA ELIMINAR CAMPOS REDUNDANTES
-- ================================================
-- Este script elimina campos que no se utilizan o son redundantes
-- IMPORTANTE: Hacer backup antes de ejecutar
-- ================================================

-- ================================================
-- 1. ELIMINAR CAMPOS NO UTILIZADOS EN nominas_generadas
-- ================================================
DO $$
BEGIN
    -- Eliminar archivo_url (no se usa, solo se usa archivo_base64)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nominas_generadas' AND column_name = 'archivo_url'
    ) THEN
        ALTER TABLE nominas_generadas DROP COLUMN archivo_url;
        RAISE NOTICE '✅ Columna archivo_url eliminada de nominas_generadas';
    END IF;

    -- Eliminar descargado (no se usa)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nominas_generadas' AND column_name = 'descargado'
    ) THEN
        ALTER TABLE nominas_generadas DROP COLUMN descargado;
        RAISE NOTICE '✅ Columna descargado eliminada de nominas_generadas';
    END IF;

    -- Eliminar descargado_en (no se usa)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nominas_generadas' AND column_name = 'descargado_en'
    ) THEN
        ALTER TABLE nominas_generadas DROP COLUMN descargado_en;
        RAISE NOTICE '✅ Columna descargado_en eliminada de nominas_generadas';
    END IF;
END $$;

-- ================================================
-- 2. ELIMINAR CAMPOS REDUNDANTES EN configuracion_pagos_trabajadores
-- ================================================
-- NOTA: Estos campos son redundantes porque ya están en asignaciones_trabajo
-- y trabajos_largo_plazo. Se pueden obtener mediante JOINs.
-- ================================================
DO $$
BEGIN
    -- Eliminar email_trabajador (redundante, está en asignaciones_trabajo)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_pagos_trabajadores' AND column_name = 'email_trabajador'
    ) THEN
        -- Eliminar constraint FK si existe
        ALTER TABLE configuracion_pagos_trabajadores 
        DROP CONSTRAINT IF EXISTS fk_config_pago_trabajador;
        
        ALTER TABLE configuracion_pagos_trabajadores DROP COLUMN email_trabajador;
        RAISE NOTICE '✅ Columna email_trabajador eliminada de configuracion_pagos_trabajadores';
    END IF;

    -- Eliminar email_contratista (redundante, está en asignaciones_trabajo y trabajos_largo_plazo)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_pagos_trabajadores' AND column_name = 'email_contratista'
    ) THEN
        -- Eliminar constraint FK si existe
        ALTER TABLE configuracion_pagos_trabajadores 
        DROP CONSTRAINT IF EXISTS fk_config_pago_contratista;
        
        ALTER TABLE configuracion_pagos_trabajadores DROP COLUMN email_contratista;
        RAISE NOTICE '✅ Columna email_contratista eliminada de configuracion_pagos_trabajadores';
    END IF;

    -- Eliminar moneda (siempre es MXN, podría ser DEFAULT)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_pagos_trabajadores' AND column_name = 'moneda'
    ) THEN
        ALTER TABLE configuracion_pagos_trabajadores DROP COLUMN moneda;
        RAISE NOTICE '✅ Columna moneda eliminada de configuracion_pagos_trabajadores (siempre es MXN)';
    END IF;
END $$;

-- ================================================
-- 3. ELIMINAR CAMPOS REDUNDANTES EN horas_laborales (OPCIONAL)
-- ================================================
-- NOTA: Estos campos son redundantes pero se recomienda MANTENERLOS
-- para mejorar el rendimiento de las consultas (denormalización intencional).
-- Descomentar solo si se quiere normalizar completamente.
-- ================================================
/*
DO $$
BEGIN
    -- Eliminar email_trabajador (redundante, está en asignaciones_trabajo)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'horas_laborales' AND column_name = 'email_trabajador'
    ) THEN
        -- Eliminar constraint FK si existe
        ALTER TABLE horas_laborales 
        DROP CONSTRAINT IF EXISTS fk_horas_trabajador;
        
        ALTER TABLE horas_laborales DROP COLUMN email_trabajador;
        RAISE NOTICE '✅ Columna email_trabajador eliminada de horas_laborales';
    END IF;

    -- Eliminar email_contratista (redundante, está en asignaciones_trabajo)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'horas_laborales' AND column_name = 'email_contratista'
    ) THEN
        -- Eliminar constraint FK si existe
        ALTER TABLE horas_laborales 
        DROP CONSTRAINT IF EXISTS fk_horas_contratista;
        
        ALTER TABLE horas_laborales DROP COLUMN email_contratista;
        RAISE NOTICE '✅ Columna email_contratista eliminada de horas_laborales';
    END IF;
END $$;
*/

-- ================================================
-- 4. ELIMINAR moneda DE pagos_premium (OPCIONAL)
-- ================================================
-- NOTA: Si siempre será MXN, se puede eliminar o dejar como DEFAULT
-- ================================================
/*
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pagos_premium' AND column_name = 'moneda'
    ) THEN
        ALTER TABLE pagos_premium DROP COLUMN moneda;
        RAISE NOTICE '✅ Columna moneda eliminada de pagos_premium (siempre es MXN)';
    END IF;
END $$;
*/

-- ================================================
-- 5. ELIMINAR moneda DE nominas_generadas (OPCIONAL)
-- ================================================
-- NOTA: Si siempre será MXN, se puede eliminar o dejar como DEFAULT
-- ================================================
/*
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nominas_generadas' AND column_name = 'moneda'
    ) THEN
        ALTER TABLE nominas_generadas DROP COLUMN moneda;
        RAISE NOTICE '✅ Columna moneda eliminada de nominas_generadas (siempre es MXN)';
    END IF;
END $$;
*/

-- ================================================
-- 6. AGREGAR moneda A gastos_extras (para consistencia)
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'gastos_extras' AND column_name = 'moneda'
    ) THEN
        ALTER TABLE gastos_extras 
        ADD COLUMN moneda VARCHAR(3) DEFAULT 'MXN';
        
        COMMENT ON COLUMN gastos_extras.moneda IS 'Moneda del gasto (por defecto MXN)';
        RAISE NOTICE '✅ Columna moneda agregada a gastos_extras';
    END IF;
END $$;

-- ================================================
-- 7. CAMBIAR TIPO DE DATO fecha_nacimiento (OPCIONAL)
-- ================================================
-- NOTA: Cambiar de VARCHAR(100) a DATE para mejor integridad
-- IMPORTANTE: Verificar que todos los datos sean convertibles antes de ejecutar
-- ================================================
/*
DO $$
BEGIN
    -- Cambiar en trabajadores
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trabajadores' 
        AND column_name = 'fecha_nacimiento' 
        AND data_type = 'character varying'
    ) THEN
        -- Primero intentar convertir los datos válidos
        UPDATE trabajadores 
        SET fecha_nacimiento = NULL 
        WHERE fecha_nacimiento !~ '^\d{4}-\d{2}-\d{2}$';
        
        -- Cambiar el tipo
        ALTER TABLE trabajadores 
        ALTER COLUMN fecha_nacimiento TYPE DATE USING fecha_nacimiento::DATE;
        
        RAISE NOTICE '✅ Tipo de fecha_nacimiento cambiado a DATE en trabajadores';
    END IF;

    -- Cambiar en contratistas
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' 
        AND column_name = 'fecha_nacimiento' 
        AND data_type = 'character varying'
    ) THEN
        -- Primero intentar convertir los datos válidos
        UPDATE contratistas 
        SET fecha_nacimiento = NULL 
        WHERE fecha_nacimiento !~ '^\d{4}-\d{2}-\d{2}$';
        
        -- Cambiar el tipo
        ALTER TABLE contratistas 
        ALTER COLUMN fecha_nacimiento TYPE DATE USING fecha_nacimiento::DATE;
        
        RAISE NOTICE '✅ Tipo de fecha_nacimiento cambiado a DATE en contratistas';
    END IF;
END $$;
*/

-- ================================================
-- FIN DEL SCRIPT
-- ================================================
-- Script ejecutado exitosamente
-- Campos redundantes eliminados
-- ================================================

