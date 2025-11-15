-- ================================================
-- CREAR TABLA: calificaciones_trabajadores
-- ================================================

CREATE TABLE IF NOT EXISTS calificaciones_trabajadores (
  id_calificacion SERIAL PRIMARY KEY,
  email_contratista VARCHAR(100) NOT NULL,
  email_trabajador VARCHAR(100) NOT NULL,
  id_asignacion INT NOT NULL,
  estrellas INT NOT NULL CHECK (estrellas BETWEEN 1 AND 5),
  resena TEXT,
  fecha_calificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_calificacion_contratista
    FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_calificacion_trabajador
    FOREIGN KEY (email_trabajador) REFERENCES trabajadores(email) ON DELETE CASCADE,
  CONSTRAINT fk_calificacion_asignacion
    FOREIGN KEY (id_asignacion) REFERENCES asignaciones_trabajo(id_asignacion) ON DELETE CASCADE,
  CONSTRAINT uq_calificacion_asignacion UNIQUE (id_asignacion)
);

CREATE INDEX IF NOT EXISTS idx_calificaciones_trabajador
  ON calificaciones_trabajadores(email_trabajador);

CREATE INDEX IF NOT EXISTS idx_calificaciones_contratista
  ON calificaciones_trabajadores(email_contratista);

COMMENT ON TABLE calificaciones_trabajadores IS 'Reseñas y calificaciones que los contratistas otorgan a los trabajadores al finalizar una asignación.';
COMMENT ON COLUMN calificaciones_trabajadores.estrellas IS 'Valor entre 1 y 5 estrellas dado por el contratista.';
COMMENT ON COLUMN calificaciones_trabajadores.resena IS 'Reseña opcional escrita por el contratista.';

