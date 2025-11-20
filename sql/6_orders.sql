-- Tabla de pedidos

CREATE TABLE IF NOT EXISTS pedidos
(
    id_pedido     SERIAL PRIMARY KEY,
    id_cliente    INT REFERENCES clientes (id_cliente)                           NOT NULL,
    folio         VARCHAR(20)                                                    NOT NULL,
    subtotal      DECIMAL(10, 2)                                                 NOT NULL,
    descuento     DECIMAL(10, 2) DEFAULT 0                                       NOT NULL,
    total         DECIMAL(10, 2)                                                 NOT NULL,
    estado        CHAR(1)        DEFAULT 'R' REFERENCES estados_pedidos (estado) NOT NULL,
    fecha_pedido  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP                       NOT NULL,
    fecha_entrega TIMESTAMP,
    activo        BOOLEAN        DEFAULT TRUE                                    NOT NULL,
    CONSTRAINT check_subtotal_positivo CHECK (subtotal >= 0),
    CONSTRAINT check_descuento_no_negativo CHECK (descuento >= 0),
    CONSTRAINT check_total_positivo CHECK (total >= 0)
);

-- Tabla de detalles

CREATE TABLE IF NOT EXISTS detalle_pedidos
(
    id_detalle  SERIAL PRIMARY KEY,
    id_pedido   INT REFERENCES pedidos (id_pedido)     NOT NULL,
    id_producto INT REFERENCES productos (id_producto) NOT NULL,
    cantidad    INT                                    NOT NULL,
    precio      DECIMAL(10, 2)                         NOT NULL,
    subtotal    DECIMAL(10, 2)                         NOT NULL,
    CONSTRAINT check_cantidad_positiva CHECK (cantidad > 0),
    CONSTRAINT check_precio_positivo CHECK (precio >= 0),
    CONSTRAINT check_subtotal_positivo CHECK (subtotal >= 0)
);

-- Índices de pedidos

CREATE INDEX idx_pedido_cliente ON pedidos (id_pedido, id_cliente, estado, fecha_pedido);

CREATE UNIQUE INDEX unique_pedido_folio ON pedidos (folio)
    WHERE activo = TRUE;

CREATE INDEX idx_detalle_pedido ON detalle_pedidos (id_pedido, id_producto);

-- Vistas de pedidos

CREATE OR REPLACE VIEW vst_pedidos_general AS
SELECT p.folio,
       c.cliente,
       c.nombre_completo,
       p.subtotal,
       p.descuento,
       p.total,
       p.estado,
       p.fecha_pedido,
       p.fecha_entrega
FROM pedidos p
         INNER JOIN vst_clientes_general c
                    ON p.id_cliente = (SELECT id_cliente FROM vst_clientes WHERE cliente = c.cliente)
WHERE p.activo = TRUE;

CREATE OR REPLACE VIEW vst_pedidos AS
SELECT *
FROM pedidos
WHERE activo = TRUE;

CREATE OR REPLACE VIEW vst_detalle_pedidos AS
SELECT dp.id_detalle,
       p.folio,
       pr.codigo,
       pr.nombre AS nombre_producto,
       dp.cantidad,
       dp.precio,
       dp.subtotal
FROM detalle_pedidos dp
         INNER JOIN pedidos p ON dp.id_pedido = p.id_pedido
         INNER JOIN productos pr ON dp.id_producto = pr.id_producto
WHERE p.activo = TRUE;

-- Funciones de pedidos

CREATE OR REPLACE FUNCTION consultar_pedidos_cliente(
    _cliente VARCHAR(20)
)
    RETURNS TABLE
            (
                total           BIGINT,
                folio           VARCHAR(20),
                cliente         VARCHAR(20),
                nombre_completo TEXT,
                subtotal        DECIMAL(10, 2),
                descuento       DECIMAL(10, 2),
                total_pedido    DECIMAL(10, 2),
                estado          CHAR(1),
                fecha_pedido    TIMESTAMP,
                fecha_entrega   TIMESTAMP
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total BIGINT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El cliente es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_pedidos_general p
    WHERE p.cliente = _cliente;

    RETURN QUERY
        SELECT v_total,
               p.folio,
               p.cliente,
               p.nombre_completo,
               p.subtotal,
               p.descuento,
               p.total,
               p.estado,
               p.fecha_pedido,
               p.fecha_entrega
        FROM vst_pedidos_general p
        WHERE p.cliente = _cliente;
END;
$$;

CREATE OR REPLACE FUNCTION consultar_pedido(
    _folio VARCHAR(20)
)
    RETURNS TABLE
            (
                id_pedido     INT,
                id_cliente    INT,
                folio         VARCHAR(20),
                subtotal      DECIMAL(10, 2),
                descuento     DECIMAL(10, 2),
                total         DECIMAL(10, 2),
                estado        CHAR(1),
                fecha_pedido  TIMESTAMP,
                fecha_entrega TIMESTAMP,
                activo        BOOLEAN
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _folio IS NULL OR TRIM(_folio) = '' THEN
        RAISE EXCEPTION 'El folio del pedido es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_pedidos p
    WHERE p.folio = _folio;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El pedido no existe';
    END IF;

    RETURN QUERY
        SELECT *
        FROM vst_pedidos p
        WHERE p.folio = _folio;
END;
$$;

CREATE OR REPLACE FUNCTION consultar_detalles_pedido(
    _folio VARCHAR(20)
)
    RETURNS TABLE
            (
                id_detalle      INT,
                folio           VARCHAR(20),
                codigo          VARCHAR(50),
                nombre_producto VARCHAR(100),
                cantidad        INT,
                precio          DECIMAL(10, 2),
                subtotal        DECIMAL(10, 2)
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _folio IS NULL OR TRIM(_folio) = '' THEN
        RAISE EXCEPTION 'El folio del pedido es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_pedidos p
    WHERE p.folio = _folio;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El pedido no existe';
    END IF;

    RETURN QUERY
        SELECT *
        FROM vst_detalle_pedidos dp
        WHERE dp.folio = _folio;
END;
$$;

CREATE OR REPLACE FUNCTION buscar_pedidos(
    _busqueda TEXT,
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total           BIGINT,
                folio           VARCHAR(20),
                cliente         VARCHAR(20),
                nombre_completo TEXT,
                subtotal        DECIMAL(10, 2),
                descuento       DECIMAL(10, 2),
                total_pedido    DECIMAL(10, 2),
                estado          CHAR(1),
                fecha_pedido    TIMESTAMP,
                fecha_entrega   TIMESTAMP
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total BIGINT;
BEGIN
    IF _busqueda IS NULL OR TRIM(_busqueda) = '' THEN
        RAISE EXCEPTION 'La búsqueda está vacía';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_pedidos_general p
    WHERE p.folio ILIKE '%' || _busqueda || '%'
       OR p.cliente ILIKE '%' || _busqueda || '%'
       OR p.nombre_completo ILIKE '%' || _busqueda || '%'
       OR p.estado::TEXT ILIKE '%' || _busqueda || '%'
       OR p.fecha_pedido::TEXT ILIKE '%' || _busqueda || '%';

    RETURN QUERY
        SELECT v_total,
               p.folio,
               p.cliente,
               p.nombre_completo,
               p.subtotal,
               p.descuento,
               p.total,
               p.estado,
               p.fecha_pedido,
               p.fecha_entrega
        FROM vst_pedidos_general p
        WHERE p.folio ILIKE '%' || _busqueda || '%'
           OR p.cliente ILIKE '%' || _busqueda || '%'
           OR p.nombre_completo ILIKE '%' || _busqueda || '%'
           OR p.estado::TEXT ILIKE '%' || _busqueda || '%'
           OR p.fecha_pedido::TEXT ILIKE '%' || _busqueda || '%'
        LIMIT _limit OFFSET _offset;
END;
$$;

CREATE OR REPLACE FUNCTION filtrar_pedidos(
    _columna_orden VARCHAR(20) DEFAULT 'fecha_pedido',
    _orden VARCHAR(4) DEFAULT 'DESC',
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total           BIGINT,
                folio           VARCHAR(20),
                cliente         VARCHAR(20),
                nombre_completo TEXT,
                subtotal        DECIMAL(10, 2),
                descuento       DECIMAL(10, 2),
                total_pedido    DECIMAL(10, 2),
                estado          CHAR(1),
                fecha_pedido    TIMESTAMP,
                fecha_entrega   TIMESTAMP
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total  BIGINT;
    consulta TEXT;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM vst_pedidos_general;

    consulta := format('
            SELECT
                %L::BIGINT,
                *
            FROM
                vst_pedidos_general
            ORDER BY
                %I %s
            LIMIT %L
            OFFSET %L',
                       v_total, _columna_orden, _orden, _limit, _offset);

    RETURN QUERY EXECUTE consulta;
END;
$$;

CREATE OR REPLACE FUNCTION registrar_pedido(
    _cliente VARCHAR(20),
    _productos JSONB,
    _descuento DECIMAL(10, 2) DEFAULT 0
)
    RETURNS TABLE
            (
                folio VARCHAR(20),
                total DECIMAL(10, 2)
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id_cliente    INT;
    v_id_pedido     INT;
    v_folio         VARCHAR(20);
    v_subtotal      DECIMAL(10, 2) := 0;
    v_total         DECIMAL(10, 2) := 0;
    v_producto      JSONB;
    v_codigo        VARCHAR(50);
    v_id_producto   INT;
    v_precio        DECIMAL(10, 2);
    v_cantidad      INT;
    v_subtotal_item DECIMAL(10, 2);
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El cliente es obligatorio';
    ELSIF _productos IS NULL OR jsonb_array_length(_productos) = 0 THEN
        RAISE EXCEPTION 'Debe incluir al menos un producto';
    ELSIF _descuento < 0 THEN
        RAISE EXCEPTION 'El descuento no puede ser negativo';
    END IF;

    SELECT id_cliente INTO v_id_cliente FROM vst_clientes WHERE cliente = _cliente;
    IF v_id_cliente IS NULL THEN
        RAISE EXCEPTION 'El cliente no existe';
    END IF;

    FOR v_producto IN SELECT * FROM jsonb_array_elements(_productos)
        LOOP
            v_codigo := (v_producto ->> 'codigo')::VARCHAR;
            v_cantidad := (v_producto ->> 'cantidad')::INT;

            SELECT id_producto, precio
            INTO v_id_producto, v_precio
            FROM vst_productos
            WHERE codigo = v_codigo;

            IF v_id_producto IS NULL THEN
                RAISE EXCEPTION 'El producto % no existe', v_codigo;
            END IF;

            IF v_cantidad <= 0 THEN
                RAISE EXCEPTION 'La cantidad debe ser mayor a 0';
            END IF;

            v_subtotal_item := v_precio * v_cantidad;
            v_subtotal := v_subtotal + v_subtotal_item;
        END LOOP;

    v_total := v_subtotal - _descuento;

    IF v_total < 0 THEN
        RAISE EXCEPTION 'El total no puede ser negativo';
    END IF;

    INSERT INTO pedidos (id_cliente, folio, subtotal, descuento, total)
    VALUES (v_id_cliente, 'TEMP', v_subtotal, _descuento, v_total)
    RETURNING id_pedido INTO v_id_pedido;

    v_folio := 'ORD'|| TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD-HH24MISS') || v_id_pedido;

    UPDATE pedidos
    SET folio = v_folio
    WHERE id_pedido = v_id_pedido;

    FOR v_producto IN SELECT * FROM jsonb_array_elements(_productos)
        LOOP
            v_codigo := (v_producto ->> 'codigo')::VARCHAR;
            v_cantidad := (v_producto ->> 'cantidad')::INT;

            SELECT id_producto, precio
            INTO v_id_producto, v_precio
            FROM vst_productos
            WHERE codigo = v_codigo;

            v_subtotal_item := v_precio * v_cantidad;

            INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio, subtotal)
            VALUES (v_id_pedido, v_id_producto, v_cantidad, v_precio, v_subtotal_item);
        END LOOP;

    RETURN QUERY SELECT v_folio, v_total;
END;
$$;

-- Procedimientos de pedidos

CREATE OR REPLACE PROCEDURE actualizar_estado_pedido(
    _folio VARCHAR(20),
    _estado VARCHAR(20)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _folio IS NULL OR TRIM(_folio) = '' THEN
        RAISE EXCEPTION 'El folio del pedido es obligatorio';
    ELSIF _estado IS NULL OR TRIM(_estado) = '' THEN
        RAISE EXCEPTION 'El estado es obligatorio';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_pedidos WHERE folio = _folio;
    IF v_total = 0 THEN
        RAISE EXCEPTION 'El pedido no existe';
    END IF;

    UPDATE pedidos
    SET estado        = _estado,
        fecha_entrega = CASE WHEN _estado = 'E' THEN CURRENT_TIMESTAMP ELSE fecha_entrega END
    WHERE folio = _folio;

    RAISE NOTICE 'El estado del pedido % se ha actualizado', _folio;
END;
$$;

CREATE OR REPLACE PROCEDURE cancelar_pedido(
    _folio VARCHAR(20)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _folio IS NULL OR TRIM(_folio) = '' THEN
        RAISE EXCEPTION 'El folio del pedido es obligatorio';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_pedidos WHERE folio = _folio;
    IF v_total = 0 THEN
        RAISE EXCEPTION 'El pedido no existe';
    END IF;

    UPDATE pedidos
    SET estado = 'C'
    WHERE folio = _folio;

    RAISE NOTICE 'El pedido % se ha cancelado correctamente', _folio;
END;
$$;

-- Triggers de pedidos

CREATE OR REPLACE FUNCTION actualizar_stock_pedido()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_stock INT;
BEGIN
    SELECT cantidad INTO v_stock FROM productos WHERE id_producto = NEW.id_producto;

    IF v_stock < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto ID %', NEW.id_producto;
    END IF;

    UPDATE productos
    SET cantidad = cantidad - NEW.cantidad
    WHERE id_producto = NEW.id_producto;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_actualizar_stock_pedido
    AFTER INSERT
    ON detalle_pedidos
    FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_pedido();

CREATE OR REPLACE FUNCTION restaurar_stock_pedido()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.estado = 'C' AND OLD.estado <> 'C' THEN
        UPDATE productos p
        SET cantidad = p.cantidad + dp.cantidad
        FROM detalle_pedidos dp
        WHERE p.id_producto = dp.id_producto
          AND dp.id_pedido = NEW.id_pedido;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_restaurar_stock_cancelacion
    AFTER UPDATE OF estado
    ON pedidos
    FOR EACH ROW
EXECUTE FUNCTION restaurar_stock_pedido();