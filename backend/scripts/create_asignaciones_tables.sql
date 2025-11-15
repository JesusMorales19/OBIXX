-- Tablas para gestionar asignaciones de trabajadores a trabajos

CREATE TABLE IF NOT EXISTS trabajos_corto_plazo_asignaciones (
  id_asignacion SERIAL PRIMARY KEY,
  id_trabajo_corto INT NOT NULL,
  email_contratista VARCHAR(100) NOT NULL,
  email_trabajador VARCHAR(100) NOT NULL,
  fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_asignacion_corto_trabajo FOREIGN KEY (id_trabajo_corto)
    REFERENCES trabajos_corto_plazo(id_trabajo_corto) ON DELETE CASCADE,
  CONSTRAINT fk_asignacion_corto_contratista FOREIGN KEY (email_contratista)
    REFERENCES contratistas(email) ON DELETE CASCADE,
  CONSTRAINT fk_asignacion_corto_trabajador FOREIGN KEY (email_trabajador)
    REFERENCES trabajadores(email) ON DELETE CASCADE,
  CONSTRAINT uq_asignacion_corto_trabajador UNIQUE (email_trabajador),
  CONSTRAINT uq_asignacion_corto UNIQUE (id_trabajo_corto, email_trabajador)
);

CREATE INDEX IF NOT EXISTS idx_asignacion_corto_trabajo
  ON trabajos_corto_plazo_asignaciones(id_trabajo_corto);

CREATE INDEX IF NOT EXISTS idx_asignacion_corto_trabajador
  ON trabajos_corto_plazo_asignaciones(email_trabajador);


CREATE TABLE IF NOT EXISTS trabajos_largo_plazo_asignaciones (
  id_asignacion SERIAL PRIMARY KEY,
  id_trabajo_largo INT NOT NULL,
  email_contratista VARCHAR(100) NOT NULL,
  email_trabajador VARCHAR(100) NOT NULL,
  fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_asignacion_largo_trabajo FOREIGN KEY (id_trabajo_largo)
    REFERENCES trabajos_largo_plazo(id_trabajo_largo) ON DELETE CASCADE,
  CONSTRAINT fk_asignacion_largo_contratista FOREIGN KEY (email_contratista)
    REFERENCES contratistas(email) ON DELETE CASCADE,
  CONSTRAINT fk_asignacion_largo_trabajador FOREIGN KEY (email_trabajador)
    REFERENCES trabajadores(email) ON DELETE CASCADE,
  CONSTRAINT uq_asignacion_largo_trabajador UNIQUE (email_trabajador),
  CONSTRAINT uq_asignacion_largo UNIQUE (id_trabajo_largo, email_trabajador)
);

CREATE INDEX IF NOT EXISTS idx_asignacion_largo_trabajo
  ON trabajos_largo_plazo_asignaciones(id_trabajo_largo);

CREATE INDEX IF NOT EXISTS idx_asignacion_largo_trabajador
  ON trabajos_largo_plazo_asignaciones(email_trabajador);
