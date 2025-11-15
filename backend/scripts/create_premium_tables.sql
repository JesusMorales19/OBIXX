-- ================================================
-- SCRIPT PARA CREAR TABLAS PREMIUM
-- Normalización 4FN (Cuarta Forma Normal)
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
COMMENT ON COLUMN planes_premium.periodicidad IS 'mensual o anual';
COMMENT ON COLUMN planes_premium.precio IS 'Precio en MXN';

-- ================================================
-- 2. TABLA: beneficios
-- ================================================
CREATE TABLE IF NOT EXISTS beneficios (
    id_beneficio SERIAL PRIMARY KEY,
    nombre_corto VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    icono VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE beneficios IS 'Catálogo de beneficios disponibles para planes premium';

-- ================================================
-- 3. TABLA: plan_beneficios (Tabla intermedia - 4FN)
-- ================================================
CREATE TABLE IF NOT EXISTS plan_beneficios (
    id_plan INTEGER NOT NULL,
    id_beneficio INTEGER NOT NULL,
    PRIMARY KEY (id_plan, id_beneficio),
    CONSTRAINT fk_plan_beneficio_plan FOREIGN KEY (id_plan)
        REFERENCES planes_premium(id_plan) ON DELETE CASCADE,
    CONSTRAINT fk_plan_beneficio_beneficio FOREIGN KEY (id_beneficio)
        REFERENCES beneficios(id_beneficio) ON DELETE CASCADE
);

COMMENT ON TABLE plan_beneficios IS 'Relación muchos a muchos entre planes y beneficios (4FN)';

-- ================================================
-- 4. TABLA: metodos_pago_contratista
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
COMMENT ON COLUMN metodos_pago_contratista.token_pasarela IS 'Token seguro de la pasarela de pagos';

-- ================================================
-- 5. TABLA: suscripciones_premium
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
-- 6. TABLA: pagos_premium
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
COMMENT ON COLUMN pagos_premium.payload_pasarela IS 'Respuesta completa de la pasarela de pagos en JSON';

-- ================================================
-- 7. TABLA: horas_laborales
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
-- 8. TABLA: presupuestos_trabajo
-- ================================================
CREATE TABLE IF NOT EXISTS presupuestos_trabajo (
    id_presupuesto SERIAL PRIMARY KEY,
    id_trabajo INTEGER NOT NULL,
    tipo_trabajo VARCHAR(20) NOT NULL CHECK (tipo_trabajo IN ('largo_plazo', 'corto_plazo')),
    email_contratista VARCHAR(100) NOT NULL,
    monto_estimado NUMERIC(12, 2) NOT NULL CHECK (monto_estimado > 0),
    moneda VARCHAR(3) DEFAULT 'MXN',
    descripcion TEXT,
    generado_por VARCHAR(100) NOT NULL,
    aprobado BOOLEAN DEFAULT false,
    fecha_aprobacion TIMESTAMP,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_presupuesto_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE presupuestos_trabajo IS 'Presupuestos por proyecto (Beneficio Premium)';
COMMENT ON COLUMN presupuestos_trabajo.tipo_trabajo IS 'largo_plazo o corto_plazo';
COMMENT ON COLUMN presupuestos_trabajo.id_trabajo IS 'ID del trabajo (largo o corto plazo)';
COMMENT ON COLUMN presupuestos_trabajo.generado_por IS 'Email del contratista que generó el presupuesto';

-- ================================================
-- 9. TABLA: pagos_semanales
-- ================================================
CREATE TABLE IF NOT EXISTS pagos_semanales (
    id_pago_semanal SERIAL PRIMARY KEY,
    id_asignacion INTEGER NOT NULL,
    email_trabajador VARCHAR(100) NOT NULL,
    email_contratista VARCHAR(100) NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    monto NUMERIC(10, 2) NOT NULL CHECK (monto >= 0),
    moneda VARCHAR(3) DEFAULT 'MXN',
    status VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'pagado', 'cancelado')),
    metodo_pago VARCHAR(50),
    comprobante_url TEXT,
    notas TEXT,
    pagado_en TIMESTAMP,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pago_semanal_asignacion FOREIGN KEY (id_asignacion)
        REFERENCES asignaciones_trabajo(id_asignacion) ON DELETE CASCADE,
    CONSTRAINT fk_pago_semanal_trabajador FOREIGN KEY (email_trabajador)
        REFERENCES trabajadores(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pago_semanal_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_periodo_fin CHECK (periodo_fin >= periodo_inicio)
);

COMMENT ON TABLE pagos_semanales IS 'Pagos semanales a trabajadores (Beneficio Premium)';
COMMENT ON COLUMN pagos_semanales.status IS 'pendiente, pagado, cancelado';
COMMENT ON COLUMN pagos_semanales.comprobante_url IS 'URL del comprobante de pago (imagen o PDF)';

-- ================================================
-- 10. TABLA: nominas_generadas
-- ================================================
CREATE TABLE IF NOT EXISTS nominas_generadas (
    id_nomina SERIAL PRIMARY KEY,
    id_trabajo INTEGER NOT NULL,
    tipo_trabajo VARCHAR(20) NOT NULL CHECK (tipo_trabajo IN ('largo_plazo', 'corto_plazo')),
    email_trabajador VARCHAR(100) NOT NULL,
    email_contratista VARCHAR(100) NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    total_horas NUMERIC(8, 2) DEFAULT 0,
    total_pagado NUMERIC(10, 2) DEFAULT 0,
    moneda VARCHAR(3) DEFAULT 'MXN',
    archivo_url TEXT,
    archivo_base64 TEXT,
    generado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descargado BOOLEAN DEFAULT false,
    descargado_en TIMESTAMP,
    CONSTRAINT fk_nomina_trabajador FOREIGN KEY (email_trabajador)
        REFERENCES trabajadores(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_nomina_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_nomina_periodo_fin CHECK (periodo_fin >= periodo_inicio)
);

COMMENT ON TABLE nominas_generadas IS 'Nóminas generadas por trabajo y trabajador (Beneficio Premium)';
COMMENT ON COLUMN nominas_generadas.tipo_trabajo IS 'largo_plazo o corto_plazo';
COMMENT ON COLUMN nominas_generadas.id_trabajo IS 'ID del trabajo (largo o corto plazo)';
COMMENT ON COLUMN nominas_generadas.archivo_url IS 'URL del archivo PDF de la nómina';
COMMENT ON COLUMN nominas_generadas.archivo_base64 IS 'Archivo PDF en Base64 para descarga directa';

-- ================================================
-- 11. MODIFICAR TABLA: contratistas
-- Agregar campos FK para mantener 4FN
-- ================================================
ALTER TABLE contratistas
ADD COLUMN IF NOT EXISTS id_suscripcion_activa INTEGER,
ADD COLUMN IF NOT EXISTS id_metodo_pago_preferido INTEGER,
ADD COLUMN IF NOT EXISTS auto_renovacion_activa BOOLEAN DEFAULT false;

-- Agregar constraints FK
ALTER TABLE contratistas
ADD CONSTRAINT IF NOT EXISTS fk_contratista_suscripcion_activa 
    FOREIGN KEY (id_suscripcion_activa)
    REFERENCES suscripciones_premium(id_suscripcion) ON DELETE SET NULL;

ALTER TABLE contratistas
ADD CONSTRAINT IF NOT EXISTS fk_contratista_metodo_pago_preferido 
    FOREIGN KEY (id_metodo_pago_preferido)
    REFERENCES metodos_pago_contratista(id_metodo) ON DELETE SET NULL;

COMMENT ON COLUMN contratistas.id_suscripcion_activa IS 'FK a suscripciones_premium (4FN) - Referencia a suscripción activa';
COMMENT ON COLUMN contratistas.id_metodo_pago_preferido IS 'FK a metodos_pago_contratista (4FN) - Método de pago predeterminado';
COMMENT ON COLUMN contratistas.auto_renovacion_activa IS 'Cache de auto-renovación (derivado de suscripción activa)';

-- ================================================
-- 12. ÍNDICES PARA MEJORAR RENDIMIENTO
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
CREATE INDEX IF NOT EXISTS idx_pagos_fecha ON pagos_premium(creado_en);

-- Índices para horas_laborales
CREATE INDEX IF NOT EXISTS idx_horas_asignacion ON horas_laborales(id_asignacion);
CREATE INDEX IF NOT EXISTS idx_horas_trabajador ON horas_laborales(email_trabajador);
CREATE INDEX IF NOT EXISTS idx_horas_fecha ON horas_laborales(fecha);

-- Índices para presupuestos_trabajo
CREATE INDEX IF NOT EXISTS idx_presupuestos_contratista ON presupuestos_trabajo(email_contratista);
CREATE INDEX IF NOT EXISTS idx_presupuestos_trabajo ON presupuestos_trabajo(tipo_trabajo, id_trabajo);

-- Índices para pagos_semanales
CREATE INDEX IF NOT EXISTS idx_pagos_semanales_asignacion ON pagos_semanales(id_asignacion);
CREATE INDEX IF NOT EXISTS idx_pagos_semanales_trabajador ON pagos_semanales(email_trabajador);
CREATE INDEX IF NOT EXISTS idx_pagos_semanales_periodo ON pagos_semanales(periodo_inicio, periodo_fin);

-- Índices para nominas_generadas
CREATE INDEX IF NOT EXISTS idx_nominas_trabajador ON nominas_generadas(email_trabajador);
CREATE INDEX IF NOT EXISTS idx_nominas_contratista ON nominas_generadas(email_contratista);
CREATE INDEX IF NOT EXISTS idx_nominas_trabajo ON nominas_generadas(tipo_trabajo, id_trabajo);

-- ================================================
-- 13. DATOS INICIALES (SEED DATA)
-- ================================================

-- Insertar planes premium
INSERT INTO planes_premium (nombre, periodicidad, precio, descripcion, activo) VALUES
    ('Plan Mensual', 'mensual', 250.00, 'Plan premium mensual con todos los beneficios', true),
    ('Plan Anual', 'anual', 2500.00, 'Plan premium anual con ahorro de 2 meses', true)
ON CONFLICT (nombre) DO NOTHING;

-- Insertar beneficios
INSERT INTO beneficios (nombre_corto, descripcion, icono) VALUES
    ('horas_laborales', 'Registro de horas laborales por trabajador', 'access_time'),
    ('presupuestos', 'Ingreso y control de presupuestos por proyecto', 'attach_money'),
    ('pagos_semanales', 'Gestión de pagos semanales a cada trabajador', 'payment'),
    ('nominas', 'Descarga o impresión de nóminas por trabajo y trabajador', 'description')
ON CONFLICT (nombre_corto) DO NOTHING;

-- Relacionar planes con beneficios (todos los planes tienen todos los beneficios)
INSERT INTO plan_beneficios (id_plan, id_beneficio)
SELECT p.id_plan, b.id_beneficio
FROM planes_premium p
CROSS JOIN beneficios b
WHERE p.activo = true
ON CONFLICT DO NOTHING;

-- ================================================
-- 14. TRIGGERS PARA ACTUALIZAR TIMESTAMPS
-- ================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar timestamps
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

CREATE TRIGGER update_presupuestos_updated_at BEFORE UPDATE ON presupuestos_trabajo
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pagos_semanales_updated_at BEFORE UPDATE ON pagos_semanales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- FIN DEL SCRIPT
-- ================================================

