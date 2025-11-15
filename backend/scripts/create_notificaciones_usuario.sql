CREATE TABLE IF NOT EXISTS notificaciones_usuario (
    id_notificacion SERIAL PRIMARY KEY,
    email_destino VARCHAR(150) NOT NULL,
    titulo TEXT NOT NULL,
    cuerpo TEXT NOT NULL,
    tipo VARCHAR(100) DEFAULT 'general',
    data_json JSONB DEFAULT '{}'::jsonb,
    imagen TEXT,
    leida BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    leida_en TIMESTAMP WITHOUT TIME ZONE,
    expira_en TIMESTAMP WITHOUT TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_email
    ON notificaciones_usuario (email_destino);

CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_expira
    ON notificaciones_usuario (expira_en);


