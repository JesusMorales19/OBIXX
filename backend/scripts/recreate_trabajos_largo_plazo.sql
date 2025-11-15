-- ================================================
-- RECREAR TABLA: trabajos_largo_plazo
-- ================================================
-- Eliminar tabla anterior y crear desde cero SIN pago_semanal

-- 1. Eliminar tabla si existe
DROP TABLE IF EXISTS trabajos_largo_plazo CASCADE;

-- 2. Crear tabla nueva
CREATE TABLE trabajos_largo_plazo (
  -- ID único del trabajo (Primary Key)
  id_trabajo_largo SERIAL PRIMARY KEY,
  
  -- Email del contratista que publica el trabajo (Foreign Key)
  email_contratista VARCHAR(100) NOT NULL,
  
  -- Información básica del trabajo
  titulo VARCHAR(150) NOT NULL,
  descripcion TEXT NOT NULL,
  
  -- Ubicación del trabajo (coordenadas GPS)
  latitud NUMERIC(10, 8),
  longitud NUMERIC(11, 8),
  direccion TEXT,
  
  -- Fechas del trabajo
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  
  -- Estado del trabajo: 'activo', 'pausado', 'completado', 'cancelado'
  estado VARCHAR(50) DEFAULT 'activo' NOT NULL,
  
  -- Vacantes disponibles
  vacantes_disponibles INT NOT NULL DEFAULT 1,
  
  -- Información adicional
  tipo_obra VARCHAR(100),
  frecuencia VARCHAR(100),
  
  -- Fecha de creación
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign Key Constraint
  CONSTRAINT fk_trabajos_largo_contratista 
    FOREIGN KEY (email_contratista) 
    REFERENCES contratistas(email) 
    ON DELETE CASCADE,
  
  -- Constraints de validación
  CONSTRAINT check_vacantes_positivas CHECK (vacantes_disponibles >= 0),
  CONSTRAINT check_fechas CHECK (fecha_fin > fecha_inicio),
  CONSTRAINT check_estado CHECK (estado IN ('activo', 'pausado', 'completado', 'cancelado'))
);

-- Índices
CREATE INDEX idx_trabajos_largo_contratista ON trabajos_largo_plazo(email_contratista);
CREATE INDEX idx_trabajos_largo_estado ON trabajos_largo_plazo(estado);
CREATE INDEX idx_trabajos_largo_ubicacion ON trabajos_largo_plazo(latitud, longitud);
CREATE INDEX idx_trabajos_largo_created ON trabajos_largo_plazo(created_at DESC);
CREATE INDEX idx_trabajos_largo_activos ON trabajos_largo_plazo(estado, vacantes_disponibles) 
  WHERE estado = 'activo' AND vacantes_disponibles > 0;

-- Comentarios
COMMENT ON TABLE trabajos_largo_plazo IS 'Trabajos de largo plazo sin pago (solo frecuencia)';
COMMENT ON COLUMN trabajos_largo_plazo.frecuencia IS 'Frecuencia de trabajo: Lunes a Viernes, Tiempo Completo, etc.';

