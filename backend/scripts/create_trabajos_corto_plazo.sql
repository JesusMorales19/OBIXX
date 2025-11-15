-- ================================================
-- CREAR TABLA: trabajos_corto_plazo
-- ================================================

CREATE TABLE IF NOT EXISTS trabajos_corto_plazo (
  id_trabajo_corto SERIAL PRIMARY KEY,
  email_contratista VARCHAR(100) NOT NULL,
  titulo VARCHAR(150) NOT NULL,
  descripcion TEXT NOT NULL,
  latitud NUMERIC(10, 8),
  longitud NUMERIC(11, 8),
  direccion TEXT,
  rango_pago VARCHAR(50) NOT NULL,
  estado VARCHAR(50) DEFAULT 'activo' NOT NULL,
  vacantes_disponibles INT NOT NULL,
  disponibilidad VARCHAR(100),
  especialidad VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tc_contratista FOREIGN KEY (email_contratista)
    REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_tc_estado CHECK (estado IN ('activo', 'pausado', 'completado', 'cancelado')),
  CONSTRAINT ck_tc_vacantes CHECK (vacantes_disponibles >= 0)
);

CREATE TABLE IF NOT EXISTS trabajos_corto_plazo_imagenes (
  id_imagen SERIAL PRIMARY KEY,
  id_trabajo_corto INT NOT NULL,
  imagen_base64 TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tc_imagen_trabajo FOREIGN KEY (id_trabajo_corto)
    REFERENCES trabajos_corto_plazo(id_trabajo_corto) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tc_ubicacion ON trabajos_corto_plazo(latitud, longitud);
CREATE INDEX IF NOT EXISTS idx_tc_estado ON trabajos_corto_plazo(estado);
CREATE INDEX IF NOT EXISTS idx_tc_email ON trabajos_corto_plazo(email_contratista);

COMMENT ON TABLE trabajos_corto_plazo IS 'Trabajos de corto plazo con rango de pago y ubicación.';
COMMENT ON COLUMN trabajos_corto_plazo.rango_pago IS 'Ejemplo: 500 - 800 MXN.';
COMMENT ON COLUMN trabajos_corto_plazo.vacantes_disponibles IS 'Número de vacantes requeridas para el trabajo corto.';
COMMENT ON COLUMN trabajos_corto_plazo.disponibilidad IS 'Urgente, siguiente semana, etc.';
COMMENT ON TABLE trabajos_corto_plazo_imagenes IS 'Lista de imágenes en Base64 asociadas a un trabajo de corto plazo.';

