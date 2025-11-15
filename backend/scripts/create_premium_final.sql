-- ================================================
-- SCRIPT FINAL PARA FUNCIONALIDAD PREMIUM
-- Normalización 4FN (Cuarta Forma Normal)
-- ================================================
-- Funcionalidades Premium:
-- 1. Registro de horas laborales por trabajador
-- 2. Presupuesto en trabajos de largo plazo (NULL por defecto)
-- 3. Configuración de pago semanal/quincenal por trabajador
-- 4. Generación de nóminas con cálculo automático
-- ================================================
-- INSTRUCCIONES: Ejecutar este script completo en PostgreSQL
-- ================================================

-- ================================================
-- 1. TABLA: planes_premium
-- ================================================
CREATE TABLE IF NOT EXISTS planes_premium (
    id_plan SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    periodicidad VARCHAR(20) NOT NULL CHECK (periodicidad IN ('mensual', 'anual')),
    precio NUMERIC(10, 2) NOT NULL CHECK (precio > 0),
    descripcion TEXT,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE planes_premium IS 'Catálogo de planes premium disponibles';

-- ================================================
-- 2. TABLA: metodos_pago_contratista
-- ================================================
CREATE TABLE IF NOT EXISTS metodos_pago_contratista (
    id_metodo SERIAL PRIMARY KEY,
    email_contratista VARCHAR(100) NOT NULL,
    alias VARCHAR(50),
    marca VARCHAR(30) NOT NULL,
    ultimos4 VARCHAR(4) NOT NULL,
    token_pasarela TEXT,
    es_predeterminado BOOLEAN DEFAULT false,
    activo BOOLEAN DEFAULT true,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_metodo_pago_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE metodos_pago_contratista IS 'Métodos de pago guardados por contratista';
COMMENT ON COLUMN metodos_pago_contratista.marca IS 'Visa, Mastercard, American Express, etc.';
COMMENT ON COLUMN metodos_pago_contratista.ultimos4 IS 'Últimos 4 dígitos de la tarjeta';

-- ================================================
-- 3. TABLA: suscripciones_premium
-- ================================================
CREATE TABLE IF NOT EXISTS suscripciones_premium (
    id_suscripcion SERIAL PRIMARY KEY,
    email_contratista VARCHAR(100) NOT NULL,
    id_plan INTEGER NOT NULL,
    id_metodo_pago INTEGER,
    fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa', 'vencida', 'cancelada', 'suspendida')),
    auto_renovacion BOOLEAN DEFAULT false,
    fecha_cancelacion TIMESTAMP,
    motivo_cancelacion TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_suscripcion_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_suscripcion_plan FOREIGN KEY (id_plan)
        REFERENCES planes_premium(id_plan) ON DELETE RESTRICT,
    CONSTRAINT fk_suscripcion_metodo_pago FOREIGN KEY (id_metodo_pago)
        REFERENCES metodos_pago_contratista(id_metodo) ON DELETE SET NULL,
    CONSTRAINT ck_fecha_fin CHECK (fecha_fin > fecha_inicio)
);

COMMENT ON TABLE suscripciones_premium IS 'Suscripciones premium de contratistas';
COMMENT ON COLUMN suscripciones_premium.estado IS 'activa, vencida, cancelada, suspendida';
COMMENT ON COLUMN suscripciones_premium.auto_renovacion IS 'Si se renueva automáticamente al vencer';

-- ================================================
-- 4. TABLA: pagos_premium
-- ================================================
CREATE TABLE IF NOT EXISTS pagos_premium (
    id_pago SERIAL PRIMARY KEY,
    id_suscripcion INTEGER NOT NULL,
    id_metodo_pago INTEGER,
    monto NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
    moneda VARCHAR(3) DEFAULT 'MXN',
    referencia_pasarela VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'completado', 'fallido', 'reembolsado')),
    payload_pasarela JSONB,
    pagado_en TIMESTAMP,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pago_suscripcion FOREIGN KEY (id_suscripcion)
        REFERENCES suscripciones_premium(id_suscripcion) ON DELETE RESTRICT,
    CONSTRAINT fk_pago_metodo FOREIGN KEY (id_metodo_pago)
        REFERENCES metodos_pago_contratista(id_metodo) ON DELETE SET NULL
);

COMMENT ON TABLE pagos_premium IS 'Historial de pagos de suscripciones premium';
COMMENT ON COLUMN pagos_premium.status IS 'pendiente, completado, fallido, reembolsado';

-- ================================================
-- 5. MODIFICAR TABLA: trabajos_largo_plazo
-- Agregar campo presupuesto (NULL por defecto, solo para premium)
-- ================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trabajos_largo_plazo' AND column_name = 'presupuesto'
    ) THEN
        ALTER TABLE trabajos_largo_plazo
        ADD COLUMN presupuesto NUMERIC(12, 2) CHECK (presupuesto IS NULL OR presupuesto >= 0);
        
        COMMENT ON COLUMN trabajos_largo_plazo.presupuesto IS 'Presupuesto total del trabajo (NULL por defecto, solo se asigna cuando el contratista tiene premium activo)';
    END IF;
END $$;

-- ================================================
-- 6. TABLA: horas_laborales
-- Registro de horas trabajadas por trabajador
-- ================================================
CREATE TABLE IF NOT EXISTS horas_laborales (
    id_registro SERIAL PRIMARY KEY,
    id_asignacion INTEGER NOT NULL,
    email_trabajador VARCHAR(100) NOT NULL,
    email_contratista VARCHAR(100) NOT NULL,
    fecha DATE NOT NULL,
    horas NUMERIC(5, 2) NOT NULL CHECK (horas > 0 AND horas <= 24),
    minutos NUMERIC(5, 2) DEFAULT 0 CHECK (minutos >= 0 AND minutos < 60),
    nota TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_horas_asignacion FOREIGN KEY (id_asignacion)
        REFERENCES asignaciones_trabajo(id_asignacion) ON DELETE CASCADE,
    CONSTRAINT fk_horas_trabajador FOREIGN KEY (email_trabajador)
        REFERENCES trabajadores(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_horas_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uk_horas_asignacion_fecha UNIQUE (id_asignacion, email_trabajador, fecha)
);

COMMENT ON TABLE horas_laborales IS 'Registro de horas trabajadas por trabajador (Beneficio Premium)';
COMMENT ON COLUMN horas_laborales.horas IS 'Horas trabajadas (0-24)';
COMMENT ON COLUMN horas_laborales.minutos IS 'Minutos adicionales (0-59)';

-- ================================================
-- 7. TABLA: configuracion_pagos_trabajadores
-- Configuración de pago semanal/quincenal por trabajador en un trabajo
-- ================================================
CREATE TABLE IF NOT EXISTS configuracion_pagos_trabajadores (
    id_configuracion SERIAL PRIMARY KEY,
    id_asignacion INTEGER NOT NULL,
    id_trabajo_largo INTEGER NOT NULL,
    -- email_trabajador y email_contratista eliminados (redundantes, se obtienen de asignaciones_trabajo)
    tipo_periodo VARCHAR(20) NOT NULL CHECK (tipo_periodo IN ('semanal', 'quincenal')),
    monto_periodo NUMERIC(10, 2) NOT NULL CHECK (monto_periodo > 0),
    moneda VARCHAR(3) DEFAULT 'MXN' CHECK (moneda IN ('MXN', 'USD')),
    horas_requeridas_periodo NUMERIC(5, 2) DEFAULT 0 CHECK (horas_requeridas_periodo >= 0),
    activo BOOLEAN DEFAULT true,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_config_pago_asignacion FOREIGN KEY (id_asignacion)
        REFERENCES asignaciones_trabajo(id_asignacion) ON DELETE CASCADE,
    CONSTRAINT fk_config_pago_trabajo FOREIGN KEY (id_trabajo_largo)
        REFERENCES trabajos_largo_plazo(id_trabajo_largo) ON DELETE CASCADE,
    -- Constraints de email_trabajador y email_contratista eliminados (redundantes)
    CONSTRAINT uk_config_asignacion UNIQUE (id_asignacion)
);

COMMENT ON TABLE configuracion_pagos_trabajadores IS 'Configuración de pago semanal/quincenal por trabajador (Beneficio Premium)';
COMMENT ON COLUMN configuracion_pagos_trabajadores.tipo_periodo IS 'semanal o quincenal';
COMMENT ON COLUMN configuracion_pagos_trabajadores.monto_periodo IS 'Monto a pagar por período (ej: $1000 por semana)';
COMMENT ON COLUMN configuracion_pagos_trabajadores.horas_requeridas_periodo IS 'Horas requeridas para completar el período (ej: 48 horas semanales)';

-- ================================================
-- 8. TABLA: nominas_generadas
-- Nóminas generadas con cálculo automático
-- ================================================
CREATE TABLE IF NOT EXISTS nominas_generadas (
    id_nomina SERIAL PRIMARY KEY,
    id_trabajo_largo INTEGER NOT NULL,
    email_contratista VARCHAR(100) NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    presupuesto_total NUMERIC(12, 2) NOT NULL CHECK (presupuesto_total >= 0),
    total_pagado_trabajadores NUMERIC(10, 2) DEFAULT 0 CHECK (total_pagado_trabajadores >= 0),
    saldo_restante NUMERIC(12, 2) DEFAULT 0 CHECK (saldo_restante >= 0),
    moneda VARCHAR(3) DEFAULT 'MXN',
    detalle_trabajadores JSONB NOT NULL,
    archivo_url TEXT,
    archivo_base64 TEXT,
    generado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descargado BOOLEAN DEFAULT false,
    descargado_en TIMESTAMP,
    CONSTRAINT fk_nomina_trabajo FOREIGN KEY (id_trabajo_largo)
        REFERENCES trabajos_largo_plazo(id_trabajo_largo) ON DELETE CASCADE,
    CONSTRAINT fk_nomina_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_nomina_periodo_fin CHECK (periodo_fin >= periodo_inicio)
    -- Nota: Se removió el constraint ck_nomina_saldo para evitar errores de redondeo
);

COMMENT ON TABLE nominas_generadas IS 'Nóminas generadas con cálculo automático (Beneficio Premium)';
COMMENT ON COLUMN nominas_generadas.presupuesto_total IS 'Presupuesto total del trabajo';
COMMENT ON COLUMN nominas_generadas.total_pagado_trabajadores IS 'Total pagado a todos los trabajadores en el período';
COMMENT ON COLUMN nominas_generadas.saldo_restante IS 'Saldo restante del presupuesto';
COMMENT ON COLUMN nominas_generadas.detalle_trabajadores IS 'JSON con detalles de cada trabajador y su pago';

-- ================================================
-- 9. MODIFICAR TABLA: contratistas
-- Agregar campos FK para mantener 4FN
-- ================================================
DO $$
BEGIN
    -- Agregar columnas si no existen
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' AND column_name = 'id_suscripcion_activa'
    ) THEN
        ALTER TABLE contratistas ADD COLUMN id_suscripcion_activa INTEGER;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' AND column_name = 'id_metodo_pago_preferido'
    ) THEN
        ALTER TABLE contratistas ADD COLUMN id_metodo_pago_preferido INTEGER;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contratistas' AND column_name = 'auto_renovacion_activa'
    ) THEN
        ALTER TABLE contratistas ADD COLUMN auto_renovacion_activa BOOLEAN DEFAULT false;
    END IF;

    -- Agregar constraints FK si no existen
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_contratista_suscripcion_activa'
    ) THEN
        ALTER TABLE contratistas
        ADD CONSTRAINT fk_contratista_suscripcion_activa 
            FOREIGN KEY (id_suscripcion_activa)
            REFERENCES suscripciones_premium(id_suscripcion) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_contratista_metodo_pago_preferido'
    ) THEN
        ALTER TABLE contratistas
        ADD CONSTRAINT fk_contratista_metodo_pago_preferido 
            FOREIGN KEY (id_metodo_pago_preferido)
            REFERENCES metodos_pago_contratista(id_metodo) ON DELETE SET NULL;
    END IF;
END $$;

COMMENT ON COLUMN contratistas.id_suscripcion_activa IS 'FK a suscripciones_premium (4FN) - Referencia a suscripción activa';
COMMENT ON COLUMN contratistas.id_metodo_pago_preferido IS 'FK a metodos_pago_contratista (4FN) - Método de pago predeterminado';
COMMENT ON COLUMN contratistas.auto_renovacion_activa IS 'Cache de auto-renovación (derivado de suscripción activa)';

-- ================================================
-- 10. ÍNDICES PARA MEJORAR RENDIMIENTO
-- ================================================

-- Índices para planes_premium
CREATE INDEX IF NOT EXISTS idx_planes_premium_activo ON planes_premium(activo);
CREATE INDEX IF NOT EXISTS idx_planes_premium_periodicidad ON planes_premium(periodicidad);

-- Índices para suscripciones_premium
CREATE INDEX IF NOT EXISTS idx_suscripciones_email ON suscripciones_premium(email_contratista);
CREATE INDEX IF NOT EXISTS idx_suscripciones_estado ON suscripciones_premium(estado);
CREATE INDEX IF NOT EXISTS idx_suscripciones_fecha_fin ON suscripciones_premium(fecha_fin);
CREATE INDEX IF NOT EXISTS idx_suscripciones_activas ON suscripciones_premium(email_contratista, estado) 
    WHERE estado = 'activa';

-- Índices para metodos_pago_contratista
CREATE INDEX IF NOT EXISTS idx_metodos_pago_email ON metodos_pago_contratista(email_contratista);
CREATE INDEX IF NOT EXISTS idx_metodos_pago_predeterminado ON metodos_pago_contratista(email_contratista, es_predeterminado) 
    WHERE es_predeterminado = true;

-- Índices para pagos_premium
CREATE INDEX IF NOT EXISTS idx_pagos_suscripcion ON pagos_premium(id_suscripcion);
CREATE INDEX IF NOT EXISTS idx_pagos_status ON pagos_premium(status);

-- Índices para horas_laborales
CREATE INDEX IF NOT EXISTS idx_horas_asignacion ON horas_laborales(id_asignacion);
CREATE INDEX IF NOT EXISTS idx_horas_trabajador ON horas_laborales(email_trabajador);
CREATE INDEX IF NOT EXISTS idx_horas_fecha ON horas_laborales(fecha);
CREATE INDEX IF NOT EXISTS idx_horas_contratista ON horas_laborales(email_contratista);

-- Índices para configuracion_pagos_trabajadores
CREATE INDEX IF NOT EXISTS idx_config_pagos_asignacion ON configuracion_pagos_trabajadores(id_asignacion);
CREATE INDEX IF NOT EXISTS idx_config_pagos_trabajo ON configuracion_pagos_trabajadores(id_trabajo_largo);
-- Índice idx_config_pagos_trabajador eliminado (email_trabajador ya no existe en esta tabla)

-- Índices para nominas_generadas
CREATE INDEX IF NOT EXISTS idx_nominas_trabajo ON nominas_generadas(id_trabajo_largo);
CREATE INDEX IF NOT EXISTS idx_nominas_contratista ON nominas_generadas(email_contratista);
CREATE INDEX IF NOT EXISTS idx_nominas_periodo ON nominas_generadas(periodo_inicio, periodo_fin);

-- ================================================
-- 11. DATOS INICIALES (SEED DATA)
-- ================================================

-- Insertar planes premium
INSERT INTO planes_premium (nombre, periodicidad, precio, descripcion, activo) VALUES
    ('Plan Mensual', 'mensual', 250.00, 'Plan premium mensual con todos los beneficios', true),
    ('Plan Anual', 'anual', 2500.00, 'Plan premium anual con ahorro de 2 meses', true)
ON CONFLICT (nombre) DO NOTHING;

-- ================================================
-- 12. TRIGGERS PARA ACTUALIZAR TIMESTAMPS
-- ================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'planes_premium' THEN
        NEW.updated_at = CURRENT_TIMESTAMP;
    ELSE
        NEW.actualizado_en = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Eliminar triggers si existen antes de crearlos
DROP TRIGGER IF EXISTS update_planes_premium_updated_at ON planes_premium;
DROP TRIGGER IF EXISTS update_metodos_pago_updated_at ON metodos_pago_contratista;
DROP TRIGGER IF EXISTS update_suscripciones_updated_at ON suscripciones_premium;
DROP TRIGGER IF EXISTS update_pagos_premium_updated_at ON pagos_premium;
DROP TRIGGER IF EXISTS update_horas_laborales_updated_at ON horas_laborales;
DROP TRIGGER IF EXISTS update_config_pagos_updated_at ON configuracion_pagos_trabajadores;

-- Crear triggers
CREATE TRIGGER update_planes_premium_updated_at BEFORE UPDATE ON planes_premium
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_metodos_pago_updated_at BEFORE UPDATE ON metodos_pago_contratista
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suscripciones_updated_at BEFORE UPDATE ON suscripciones_premium
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pagos_premium_updated_at BEFORE UPDATE ON pagos_premium
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_horas_laborales_updated_at BEFORE UPDATE ON horas_laborales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_config_pagos_updated_at BEFORE UPDATE ON configuracion_pagos_trabajadores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- FIN DEL SCRIPT
-- ================================================
-- Script ejecutado exitosamente
-- Todas las tablas, índices, triggers y datos iniciales han sido creados
-- ================================================

