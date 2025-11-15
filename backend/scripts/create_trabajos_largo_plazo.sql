-- ================================================
-- CREAR TABLA: trabajos_largo_plazo
-- ================================================
-- Tabla para almacenar trabajos de largo plazo publicados por contratistas
-- Con ubicación usando latitud y longitud para búsquedas cercanas

CREATE TABLE IF NOT EXISTS trabajos_largo_plazo (
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
    ON DELETE CASCADE ON UPDATE CASCADE,
  
  -- Constraints de validación
  CONSTRAINT check_vacantes_positivas CHECK (vacantes_disponibles >= 0),
  CONSTRAINT check_fechas CHECK (fecha_fin > fecha_inicio),
  CONSTRAINT check_estado CHECK (estado IN ('activo', 'pausado', 'completado', 'cancelado'))
);

-- ================================================
-- ÍNDICES para mejorar el rendimiento
-- ================================================

-- Índice para búsquedas por contratista
CREATE INDEX IF NOT EXISTS idx_trabajos_largo_contratista 
  ON trabajos_largo_plazo(email_contratista);

-- Índice para búsquedas por estado
CREATE INDEX IF NOT EXISTS idx_trabajos_largo_estado 
  ON trabajos_largo_plazo(estado);

-- Índice para búsquedas por ubicación (latitud, longitud)
CREATE INDEX IF NOT EXISTS idx_trabajos_largo_ubicacion 
  ON trabajos_largo_plazo(latitud, longitud);

-- Índice para ordenar por fecha de creación
CREATE INDEX IF NOT EXISTS idx_trabajos_largo_created 
  ON trabajos_largo_plazo(created_at DESC);

-- Índice compuesto para búsquedas de trabajos activos con vacantes
CREATE INDEX IF NOT EXISTS idx_trabajos_largo_activos 
  ON trabajos_largo_plazo(estado, vacantes_disponibles) 
  WHERE estado = 'activo' AND vacantes_disponibles > 0;

-- ================================================
-- COMENTARIOS en las columnas
-- ================================================

COMMENT ON TABLE trabajos_largo_plazo IS 'Trabajos de largo plazo publicados por contratistas';
COMMENT ON COLUMN trabajos_largo_plazo.id_trabajo_largo IS 'ID único del trabajo';
COMMENT ON COLUMN trabajos_largo_plazo.email_contratista IS 'Email del contratista que publica el trabajo';
COMMENT ON COLUMN trabajos_largo_plazo.latitud IS 'Latitud GPS del lugar del trabajo';
COMMENT ON COLUMN trabajos_largo_plazo.longitud IS 'Longitud GPS del lugar del trabajo';
COMMENT ON COLUMN trabajos_largo_plazo.direccion IS 'Dirección legible del trabajo (opcional)';
COMMENT ON COLUMN trabajos_largo_plazo.estado IS 'Estado actual del trabajo: activo, pausado, completado, cancelado';
COMMENT ON COLUMN trabajos_largo_plazo.vacantes_disponibles IS 'Número de vacantes disponibles';
COMMENT ON COLUMN trabajos_largo_plazo.tipo_obra IS 'Tipo de obra: Construcción, Remodelación, etc.';
COMMENT ON COLUMN trabajos_largo_plazo.frecuencia IS 'Frecuencia de trabajo: Lunes a Viernes, Tiempo Completo, etc.';

-- ================================================
-- DATOS DE PRUEBA (Opcional - Comentar si no se necesitan)
-- ================================================

-- Insertar un trabajo de ejemplo (ajusta el email_contratista según tu BD)
/*
INSERT INTO trabajos_largo_plazo (
  email_contratista,
  titulo,
  descripcion,
  latitud,
  longitud,
  direccion,
  fecha_inicio,
  fecha_fin,
  estado,
  vacantes_disponibles,
  tipo_obra,
  frecuencia
) VALUES (
  'contratista@ejemplo.com',  -- Ajustar según el email de un contratista existente
  'Construcción de Casa Habitación',
  'Se requieren albañiles con experiencia en construcción de casas. El trabajo incluye cimentación, muros, techos y acabados.',
  20.659699,  -- Latitud de ejemplo (Guadalajara)
  -103.349609,  -- Longitud de ejemplo (Guadalajara)
  'Av. Vallarta 1234, Col. Americana, Guadalajara, Jalisco',
  '2025-02-01',
  '2025-08-31',
  'activo',
  5,
  'Construcción',
  'Lunes a Viernes, 8:00 AM - 5:00 PM'
);
*/

-- ================================================
-- VERIFICAR LA TABLA CREADA
-- ================================================

-- Consultar la estructura de la tabla
-- SELECT column_name, data_type, character_maximum_length 
-- FROM information_schema.columns 
-- WHERE table_name = 'trabajos_largo_plazo';

-- Consultar los índices creados
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'trabajos_largo_plazo';

