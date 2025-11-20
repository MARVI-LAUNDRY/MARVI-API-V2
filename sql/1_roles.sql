-- Tabla roles

CREATE TABLE IF NOT EXISTS roles
(
    rol    CHAR(1) PRIMARY KEY,
    nombre VARCHAR(14) NOT NULL
);

-- Índices de roles

CREATE INDEX idx_rol_nombre ON roles (nombre);

-- Vistas de roles

CREATE OR REPLACE VIEW vst_roles AS
SELECT *
FROM roles;

-- Default

INSERT INTO roles (rol, nombre)
VALUES ('A', 'Administrador'),
       ('U', 'Usuario'),
       ('I', 'Invitado');

-- Pruebas

SELECT * FROM vst_roles;