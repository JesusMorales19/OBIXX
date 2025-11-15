-- ================================================
-- TABLA: gastos_extras
-- Gastos adicionales del contratista (materiales, herramientas, etc.)
-- ================================================
CREATE TABLE IF NOT EXISTS gastos_extras (
    id_gasto SERIAL PRIMARY KEY,
    id_trabajo_largo INTEGER NOT NULL,
    email_contratista VARCHAR(100) NOT NULL,
    fecha_gasto DATE NOT NULL,
    monto NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
    descripcion TEXT NOT NULL,
    moneda VARCHAR(3) DEFAULT 'MXN',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gasto_trabajo FOREIGN KEY (id_trabajo_largo)
        REFERENCES trabajos_largo_plazo(id_trabajo_largo) ON DELETE CASCADE,
    CONSTRAINT fk_gasto_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Índices para mejorar consultas
CREATE INDEX IF NOT EXISTS idx_gastos_trabajo ON gastos_extras(id_trabajo_largo);
CREATE INDEX IF NOT EXISTS idx_gastos_contratista ON gastos_extras(email_contratista);
CREATE INDEX IF NOT EXISTS idx_gastos_fecha ON gastos_extras(fecha_gasto);

COMMENT ON TABLE gastos_extras IS 'Gastos adicionales del contratista (materiales, herramientas, etc.) por trabajo';
COMMENT ON COLUMN gastos_extras.descripcion IS 'Descripción del gasto (ej: "Compra de cemento", "Herramientas eléctricas")';

-- ================================================
-- MODIFICAR TABLA: nominas_generadas
-- Agregar campos para gastos extras
-- ================================================
DO $$
BEGIN
    -- Agregar columna total_gastos_extras si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nominas_generadas' AND column_name = 'total_gastos_extras'
    ) THEN
        ALTER TABLE nominas_generadas
        ADD COLUMN total_gastos_extras NUMERIC(10, 2) DEFAULT 0 CHECK (total_gastos_extras >= 0);
        
        COMMENT ON COLUMN nominas_generadas.total_gastos_extras IS 'Total de gastos extras en el período';
    END IF;
    
    -- Agregar columna detalle_gastos_extras si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nominas_generadas' AND column_name = 'detalle_gastos_extras'
    ) THEN
        ALTER TABLE nominas_generadas
        ADD COLUMN detalle_gastos_extras JSONB DEFAULT '[]'::jsonb;
        
        COMMENT ON COLUMN nominas_generadas.detalle_gastos_extras IS 'JSON con detalles de gastos extras: [{"fecha": "2025-01-15", "descripcion": "Cemento", "monto": 5000.00}, ...]';
    END IF;
END $$;

-- Actualizar constraint de saldo_restante para incluir gastos extras
-- (Se calcula: presupuesto_total - total_pagado_trabajadores - total_gastos_extras)
-- Nota: Se mantiene flexible para evitar errores de redondeo

