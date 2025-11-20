-- Tabla de estados

CREATE TABLE IF NOT EXISTS estados_pedidos
(
    estado CHAR(1) PRIMARY KEY,
    nombre VARCHAR(14) NOT NULL
);

-- Índices de estados

CREATE INDEX idx_estado_pedido_nombre ON estados_pedidos (nombre);

-- Vistas de estados

CREATE OR REPLACE VIEW vst_estados_pedidos AS
SELECT *
FROM estados_pedidos;

-- Default

INSERT INTO estados_pedidos (estado, nombre)
VALUES ('R', 'Procesando'),
       ('P', 'Pagado'),
       ('E', 'Entregado'),
       ('D', 'Devuelto'),
       ('C', 'Cancelado');

-- Pruebas

SELECT *
FROM vst_estados_pedidos;