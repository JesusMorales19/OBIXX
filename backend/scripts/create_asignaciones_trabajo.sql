CREATE TABLE IF NOT EXISTS asignaciones_trabajo (
  id_asignacion SERIAL PRIMARY KEY,
  email_contratista VARCHAR(100) NOT NULL,
  email_trabajador VARCHAR(100) NOT NULL,
  tipo_trabajo VARCHAR(20) NOT NULL CHECK (tipo_trabajo IN ('corto', 'largo')),
  id_trabajo INT NOT NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'cancelado', 'finalizado')),
  fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_cancelacion TIMESTAMP,
  CONSTRAINT fk_asignacion_contratista FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_asignacion_trabajador FOREIGN KEY (email_trabajador) REFERENCES trabajadores(email) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_asignacion_trabajador_activo
ON asignaciones_trabajo(email_trabajador)
WHERE estado = 'activo';
