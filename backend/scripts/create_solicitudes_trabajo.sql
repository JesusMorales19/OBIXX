CREATE TABLE IF NOT EXISTS solicitudes_trabajo (
    id_solicitud SERIAL PRIMARY KEY,
    email_trabajador VARCHAR(120) NOT NULL,
    email_contratista VARCHAR(120) NOT NULL,
    tipo_trabajo VARCHAR(10) NOT NULL CHECK (tipo_trabajo IN ('corto', 'largo')),
    id_trabajo INTEGER NOT NULL,
    estado VARCHAR(15) NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'expirada', 'cancelada')),
    creado_en TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_en TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '10 minutes'),
    respondido_en TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_solicitud_trabajador FOREIGN KEY (email_trabajador)
        REFERENCES trabajadores(email) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_solicitud_contratista FOREIGN KEY (email_contratista)
        REFERENCES contratistas(email) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_trabajo_trabajador_estado
    ON solicitudes_trabajo (email_trabajador, estado);

CREATE INDEX IF NOT EXISTS idx_solicitudes_trabajo_expira_en
    ON solicitudes_trabajo (expira_en);


