-- Script para crear las tablas de contratistas y trabajadores

-- Tabla de Contratistas
CREATE TABLE IF NOT EXISTS contratistas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    genero VARCHAR(20) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Trabajadores
CREATE TABLE IF NOT EXISTS trabajadores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    genero VARCHAR(20) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    experiencia INTEGER NOT NULL DEFAULT 0,
    categoria VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar las búsquedas
CREATE INDEX IF NOT EXISTS idx_contratistas_correo ON contratistas(correo);
CREATE INDEX IF NOT EXISTS idx_trabajadores_correo ON trabajadores(correo);
CREATE INDEX IF NOT EXISTS idx_trabajadores_categoria ON trabajadores(categoria);











