-- Tabla productos

CREATE TABLE IF NOT EXISTS productos
(
    id_producto    SERIAL PRIMARY KEY,
    codigo         VARCHAR(50)                         NOT NULL,
    nombre         VARCHAR(100)                        NOT NULL,
    descripcion    TEXT      DEFAULT ''                NOT NULL,
    precio         DECIMAL(10, 2)                      NOT NULL,
    cantidad       INT       DEFAULT 0                 NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    imagen_url     TEXT      DEFAULT ''                NOT NULL,
    activo         BOOLEAN   DEFAULT TRUE              NOT NULL,
    CONSTRAINT check_precio_positivo CHECK (precio >= 0),
    CONSTRAINT check_cantidad_no_negativa CHECK (cantidad >= 0)
);

-- Índices de productos

CREATE INDEX idx_producto_busqueda ON productos (
                                                 codigo,
                                                 nombre,
                                                 descripcion,
                                                 precio,
                                                 cantidad,
                                                 fecha_registro
    );

CREATE INDEX idx_producto_activo ON productos (activo);

CREATE UNIQUE INDEX unique_producto_codigo ON productos (codigo)
    WHERE activo = TRUE;

-- Vistas de productos

CREATE OR REPLACE VIEW vst_productos_general AS
SELECT p.codigo,
       p.nombre,
       p.descripcion,
       p.precio,
       p.cantidad,
       p.fecha_registro,
       p.imagen_url
FROM productos p
WHERE p.activo = TRUE;

CREATE OR REPLACE VIEW vst_productos AS
SELECT *
FROM productos
WHERE activo = TRUE;

-- Funciones de productos

CREATE OR REPLACE FUNCTION consultar_producto(
    _codigo VARCHAR(50)
)
    RETURNS TABLE
            (
                id_producto    INT,
                codigo         VARCHAR(50),
                nombre         VARCHAR(100),
                descripcion    TEXT,
                precio         DECIMAL(10, 2),
                cantidad       INT,
                fecha_registro TIMESTAMP,
                imagen_url     TEXT,
                activo         BOOLEAN
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _codigo IS NULL OR TRIM(_codigo) = '' THEN
        RAISE EXCEPTION 'El código del producto es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_productos p
    WHERE p.codigo = _codigo;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El producto no existe';
    END IF;

    RETURN QUERY
        SELECT *
        FROM vst_productos p
        WHERE p.codigo = _codigo;
END;
$$;

CREATE OR REPLACE FUNCTION buscar_productos(
    _busqueda TEXT,
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total          BIGINT,
                codigo         VARCHAR(50),
                nombre         VARCHAR(100),
                descripcion    TEXT,
                precio         DECIMAL(10, 2),
                cantidad       INT,
                fecha_registro TIMESTAMP,
                imagen_url     TEXT
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
    FROM vst_productos_general p
    WHERE p.codigo ILIKE '%' || _busqueda || '%'
       OR p.nombre ILIKE '%' || _busqueda || '%'
       OR p.descripcion ILIKE '%' || _busqueda || '%'
       OR p.precio::TEXT ILIKE '%' || _busqueda || '%'
       OR p.cantidad::TEXT ILIKE '%' || _busqueda || '%'
       OR p.fecha_registro::TEXT ILIKE '%' || _busqueda || '%';

    RETURN QUERY
        SELECT v_total,
               *
        FROM vst_productos_general p
        WHERE p.codigo ILIKE '%' || _busqueda || '%'
           OR p.nombre ILIKE '%' || _busqueda || '%'
           OR p.descripcion ILIKE '%' || _busqueda || '%'
           OR p.precio::TEXT ILIKE '%' || _busqueda || '%'
           OR p.cantidad::TEXT ILIKE '%' || _busqueda || '%'
           OR p.fecha_registro::TEXT ILIKE '%' || _busqueda || '%'
        LIMIT _limit OFFSET _offset;
END;
$$;

CREATE OR REPLACE FUNCTION filtrar_productos(
    _columna_orden VARCHAR(15) DEFAULT 'nombre',
    _orden VARCHAR(4) DEFAULT 'ASC',
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total          BIGINT,
                codigo         VARCHAR(50),
                nombre         VARCHAR(100),
                descripcion    TEXT,
                precio         DECIMAL(10, 2),
                cantidad       INT,
                fecha_registro TIMESTAMP,
                imagen_url     TEXT
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total            BIGINT;
    DECLARE consulta TEXT;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM vst_productos_general;

    consulta := format('
             SELECT
                 %L::BIGINT,
                 *
             FROM
                 vst_productos_general
             ORDER BY
                 %I %s
             LIMIT %L
             OFFSET %L',
                       v_total, _columna_orden, _orden, _limit, _offset);

    RETURN QUERY EXECUTE consulta;
END;
$$;

-- Procedimientos de productos

CREATE OR REPLACE PROCEDURE registrar_producto(
    _codigo VARCHAR(50),
    _nombre VARCHAR(100),
    _descripcion TEXT,
    _precio DECIMAL(10, 2),
    _cantidad INT DEFAULT 0,
    _imagen_url TEXT DEFAULT ''
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _codigo IS NULL OR TRIM(_codigo) = '' THEN
        RAISE EXCEPTION 'El código del producto es obligatorio';
    ELSIF _nombre IS NULL OR TRIM(_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre del producto es obligatorio';
    ELSIF _precio IS NULL OR _precio < 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor o igual a 0';
    ELSIF _cantidad IS NULL OR _cantidad < 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor o igual a 0';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_productos p WHERE p.codigo = _codigo;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El código del producto ya está registrado';
    END IF;

    INSERT INTO productos (codigo, nombre, descripcion, precio, cantidad, imagen_url)
    VALUES (_codigo,
            _nombre,
            _descripcion,
            _precio,
            _cantidad,
            _imagen_url);

    RAISE NOTICE 'El producto % se ha registrado correctamente', _codigo;
END;
$$;

CREATE OR REPLACE PROCEDURE actualizar_producto(
    _id_producto INT,
    _codigo VARCHAR(50),
    _nombre VARCHAR(100),
    _descripcion TEXT,
    _precio DECIMAL(10, 2),
    _cantidad INT DEFAULT 0,
    _imagen_url TEXT DEFAULT ''
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _id_producto IS NULL OR _id_producto <= 0 THEN
        RAISE EXCEPTION 'El identificador del producto es obligatorio';
    ELSIF _codigo IS NULL OR TRIM(_codigo) = '' THEN
        RAISE EXCEPTION 'El código del producto es obligatorio';
    ELSIF _nombre IS NULL OR TRIM(_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre del producto es obligatorio';
    ELSIF _precio IS NULL OR _precio < 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor o igual a 0';
    ELSIF _cantidad IS NULL OR _cantidad < 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor o igual a 0';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_productos p
    WHERE p.id_producto = _id_producto;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El producto no existe';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_productos p WHERE p.codigo = _codigo AND p.id_producto <> _id_producto;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El código del producto ya está registrado';
    END IF;

    UPDATE
        productos
    SET codigo      = _codigo,
        nombre      = _nombre,
        descripcion = _descripcion,
        precio      = _precio,
        cantidad    = _cantidad,
        imagen_url  = _imagen_url
    WHERE id_producto = _id_producto;

    RAISE NOTICE 'El producto % se ha actualizado correctamente', _codigo;
END;
$$;

CREATE OR REPLACE PROCEDURE eliminar_producto(
    _codigo VARCHAR(50)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _codigo IS NULL OR TRIM(_codigo) = '' THEN
        RAISE EXCEPTION 'El código del producto es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_productos p
    WHERE p.codigo = _codigo;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El producto no existe';
    END IF;

    UPDATE
        productos
    SET activo = FALSE
    WHERE codigo = _codigo;

    RAISE NOTICE 'El producto % se ha eliminado correctamente', _codigo;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_cantidad_producto(
    _codigo VARCHAR(50),
    _cantidad INT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _codigo IS NULL OR TRIM(_codigo) = '' THEN
        RAISE EXCEPTION 'El código del producto es obligatorio';
    ELSIF _cantidad IS NULL THEN
        RAISE EXCEPTION 'La cantidad es obligatoria';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_productos p
    WHERE p.codigo = _codigo;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El producto no existe';
    END IF;

    UPDATE
        productos
    SET cantidad = _cantidad
    WHERE codigo = _codigo;

    RAISE NOTICE 'La existencia del producto % se ha actualizado correctamente', _codigo;
END;
$$;