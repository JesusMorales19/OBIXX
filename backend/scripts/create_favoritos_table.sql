-- Tabla para gestionar favoritos de contratistas
-- Un contratista puede tener múltiples trabajadores favoritos

CREATE TABLE IF NOT EXISTS favoritos (
  id_favorito SERIAL PRIMARY KEY,
  email_contratista VARCHAR(100) NOT NULL,
  email_trabajador VARCHAR(100) NOT NULL,
  fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign keys
  CONSTRAINT fk_contratista FOREIGN KEY (email_contratista) 
    REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_trabajador FOREIGN KEY (email_trabajador) 
    REFERENCES trabajadores(email) ON DELETE CASCADE,
  
  -- Un contratista no puede tener el mismo trabajador como favorito más de una vez
  CONSTRAINT unique_favorito UNIQUE (email_contratista, email_trabajador)
);

-- Índices para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_favoritos_contratista ON favoritos(email_contratista);
CREATE INDEX IF NOT EXISTS idx_favoritos_trabajador ON favoritos(email_trabajador);

