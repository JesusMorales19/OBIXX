CREATE TABLE IF NOT EXISTS dispositivos_notificaciones (
    id_dispositivo SERIAL PRIMARY KEY,
    email VARCHAR(150) NOT NULL,
    tipo_usuario VARCHAR(50) NOT NULL,
    token TEXT NOT NULL UNIQUE,
    plataforma VARCHAR(50) DEFAULT 'desconocida',
    creado_en TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dispositivos_notificaciones_email
    ON dispositivos_notificaciones (email);


