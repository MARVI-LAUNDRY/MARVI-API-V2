-- Tabla clientes

CREATE TABLE IF NOT EXISTS clientes
(
    id_cliente       SERIAL PRIMARY KEY,
    cliente          VARCHAR(30)                           NOT NULL,
    nombre           VARCHAR(50)                           NOT NULL,
    primer_apellido  VARCHAR(50)                           NOT NULL,
    segundo_apellido VARCHAR(50) DEFAULT ''                NOT NULL,
    correo           VARCHAR(100)                          NOT NULL,
    contrasena       TEXT                                  NOT NULL,
    telefono         VARCHAR(15) DEFAULT ''                NOT NULL,
    direccion        TEXT        DEFAULT ''                NOT NULL,
    fecha_registro   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL,
    imagen_src       TEXT        DEFAULT ''                NOT NULL,
    activo           BOOLEAN     DEFAULT TRUE              NOT NULL
);

-- Índices de clientes

CREATE INDEX idx_cliente_busqueda ON clientes (
                                               cliente,
                                               nombre,
                                               primer_apellido,
                                               segundo_apellido,
                                               correo,
                                               telefono,
                                               fecha_registro
    );

CREATE INDEX idx_cliente_activo ON clientes (activo);

CREATE UNIQUE INDEX unique_cliente_cliente ON clientes (cliente)
    WHERE activo = TRUE;

CREATE UNIQUE INDEX unique_cliente_correo ON clientes (correo)
    WHERE activo = TRUE;

-- Vistas de clientes

CREATE OR REPLACE VIEW vst_clientes_general AS
SELECT c.cliente,
       TRIM(CONCAT(
               c.nombre,
               ' ',
               c.primer_apellido,
               ' ',
               c.segundo_apellido
            )) AS nombre_completo,
       c.correo,
       c.telefono,
       c.direccion,
       c.fecha_registro
FROM clientes c
WHERE c.activo = TRUE;

CREATE OR REPLACE VIEW vst_clientes AS
SELECT *
FROM clientes
WHERE activo = TRUE;

-- Funciones de clientes

CREATE OR REPLACE FUNCTION iniciar_sesion_clientes(
    _cliente VARCHAR(30)
)
    RETURNS TABLE
            (
                contrasena TEXT
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.cliente = _cliente;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    RETURN QUERY
        SELECT c.contrasena
        FROM vst_clientes c
        WHERE c.cliente = _cliente;
END;
$$;

CREATE OR REPLACE FUNCTION consultar_cliente(
    _cliente VARCHAR(30)
)
    RETURNS TABLE
            (
                id_cliente       INT,
                cliente          VARCHAR(30),
                nombre           VARCHAR(50),
                primer_apellido  VARCHAR(50),
                segundo_apellido VARCHAR(50),
                correo           VARCHAR(100),
                contrasena       TEXT,
                telefono         VARCHAR(15),
                direccion        TEXT,
                fecha_registro   TIMESTAMP,
                imagen_src       TEXT,
                activo           BOOLEAN
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.cliente = _cliente;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    RETURN QUERY
        SELECT *
        FROM vst_clientes c
        WHERE c.cliente = _cliente;
END;
$$;

CREATE OR REPLACE FUNCTION consultar_cliente_por_correo(
    _correo VARCHAR(100)
)
    RETURNS TABLE
            (
                id_cliente       INT,
                cliente          VARCHAR(30),
                nombre           VARCHAR(50),
                primer_apellido  VARCHAR(50),
                segundo_apellido VARCHAR(50),
                correo           VARCHAR(100),
                contrasena       TEXT,
                telefono         VARCHAR(15),
                direccion        TEXT,
                fecha_registro   TIMESTAMP,
                imagen_src       TEXT,
                activo           BOOLEAN
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _correo IS NULL OR TRIM(_correo) = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.correo = LOWER(_correo);

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El correo electrónico no existe';
    END IF;

    RETURN QUERY
        SELECT *
        FROM vst_clientes c
        WHERE c.correo = LOWER(_correo);
END;
$$;

CREATE OR REPLACE FUNCTION buscar_clientes(
    _busqueda TEXT,
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total           BIGINT,
                cliente         VARCHAR(30),
                nombre_completo TEXT,
                correo          VARCHAR(100),
                telefono        VARCHAR(15),
                direccion       TEXT,
                fecha_registro  TIMESTAMP
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
    FROM vst_clientes_general c
    WHERE c.cliente ILIKE '%' || _busqueda || '%'
       OR c.nombre_completo ILIKE '%' || _busqueda || '%'
       OR c.correo ILIKE '%' || _busqueda || '%'
       OR c.telefono ILIKE '%' || _busqueda || '%'
       OR c.direccion ILIKE '%' || _busqueda || '%'
       OR c.fecha_registro::TEXT ILIKE '%' || _busqueda || '%';

    RETURN QUERY
        SELECT v_total,
               *
        FROM vst_clientes_general c
        WHERE c.cliente ILIKE '%' || _busqueda || '%'
           OR c.nombre_completo ILIKE '%' || _busqueda || '%'
           OR c.correo ILIKE '%' || _busqueda || '%'
           OR c.telefono ILIKE '%' || _busqueda || '%'
           OR c.direccion ILIKE '%' || _busqueda || '%'
           OR c.fecha_registro::TEXT ILIKE '%' || _busqueda || '%'
        LIMIT _limit OFFSET _offset;
END;
$$;

CREATE OR REPLACE FUNCTION filtrar_clientes(
    _columna_orden VARCHAR(15) DEFAULT 'nombre_completo',
    _orden VARCHAR(4) DEFAULT 'ASC',
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total           BIGINT,
                cliente         VARCHAR(30),
                nombre_completo TEXT,
                correo          VARCHAR(100),
                telefono        VARCHAR(15),
                direccion       TEXT,
                fecha_registro  TIMESTAMP
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total          BIGINT;
    DECLARE consulta TEXT;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes_general;

    consulta := format('
            SELECT
                %L::BIGINT,
                *
            FROM
                vst_clientes_general
            ORDER BY
                %I %s
            LIMIT %L
            OFFSET %L',
                       v_total, _columna_orden, _orden, _limit, _offset);

    RETURN QUERY EXECUTE consulta;
END;
$$;

-- Procedimientos de clientes

CREATE OR REPLACE PROCEDURE registrar_cliente(
    _cliente VARCHAR(30),
    _nombre VARCHAR(50),
    _primer_apellido VARCHAR(50),
    _segundo_apellido VARCHAR(50),
    _correo VARCHAR(100),
    _contrasena TEXT,
    _imagen_src TEXT DEFAULT '',
    _telefono VARCHAR(15) DEFAULT '',
    _direccion TEXT DEFAULT ''
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _nombre IS NULL OR TRIM(_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre es obligatorio';
    ELSIF _primer_apellido IS NULL OR TRIM(_primer_apellido) = '' THEN
        RAISE EXCEPTION 'El primer apellido es obligatorio';
    ELSIF _segundo_apellido IS NULL THEN
        _segundo_apellido = '';
    ELSIF _correo IS NULL OR TRIM(_correo) = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_clientes c WHERE c.cliente = _cliente;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El usuario ya esta registrado';
    END IF;

    IF _correo !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'El correo electrónico no tiene un formato válido';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_clientes c WHERE c.correo = _correo;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El correo electrónico ya esta registrado';
    END IF;

    INSERT INTO clientes (cliente, nombre, primer_apellido, segundo_apellido, correo, contrasena, telefono, direccion, imagen_src)
    VALUES (_cliente,
            _nombre,
            _primer_apellido,
            _segundo_apellido,
            LOWER(_correo),
            _contrasena,
            _telefono,
            _direccion,
            _imagen_src);

    RAISE NOTICE 'El usuario % se ha registrado correctamente', _cliente;
END;
$$;

CREATE OR REPLACE PROCEDURE actualizar_cliente(
    _id_cliente INT,
    _cliente VARCHAR(30),
    _nombre VARCHAR(50),
    _primer_apellido VARCHAR(50),
    _segundo_apellido VARCHAR(50),
    _correo VARCHAR(100),
    _telefono VARCHAR(15) DEFAULT '',
    _direccion TEXT DEFAULT ''
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _id_cliente IS NULL OR _id_cliente <= 0 THEN
        RAISE EXCEPTION 'El identificador del cliente es obligatorio';
    ELSIF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _nombre IS NULL OR TRIM(_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre es obligatorio';
    ELSIF _primer_apellido IS NULL OR TRIM(_primer_apellido) = '' THEN
        RAISE EXCEPTION 'El primer apellido es obligatorio';
    ELSIF _correo IS NULL OR TRIM(_correo) = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio';
    END IF;

    IF _correo !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'El correo electrónico no tiene un formato válido';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.id_cliente = _id_cliente;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_clientes c WHERE c.cliente = _cliente AND c.id_cliente <> _id_cliente;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El usuario ya esta registrado';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_clientes c WHERE c.correo = _correo AND c.id_cliente <> _id_cliente;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El correo electrónico ya esta registrado';
    END IF;

    UPDATE
        clientes
    SET cliente          = _cliente,
        nombre           = _nombre,
        primer_apellido  = _primer_apellido,
        segundo_apellido = _segundo_apellido,
        correo           = LOWER(_correo),
        telefono         = _telefono,
        direccion        = _direccion
    WHERE id_cliente = _id_cliente;

    RAISE NOTICE 'El usuario % se ha actualizado correctamente', _cliente;
END;
$$;

CREATE OR REPLACE PROCEDURE eliminar_cliente(
    _cliente VARCHAR(30)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.cliente = _cliente;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    UPDATE
        clientes
    SET activo = FALSE
    WHERE cliente = _cliente;

    RAISE NOTICE 'El usuario % se ha eliminado correctamente', _cliente;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_contrasena_cliente(
    _cliente VARCHAR(30),
    _contrasena TEXT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _contrasena IS NULL OR TRIM(_contrasena) = '' THEN
        RAISE EXCEPTION 'La contraseña es obligatoria';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.cliente = _cliente;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    UPDATE
        clientes
    SET contrasena = _contrasena
    WHERE cliente = _cliente;
    RAISE NOTICE 'La contraseña del usuario % se ha actualizado correctamente', _cliente;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_imagen_cliente(
    _cliente VARCHAR(30),
    _imagen_src TEXT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _cliente IS NULL OR TRIM(_cliente) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_clientes c
    WHERE c.cliente = _cliente;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    UPDATE
        clientes
    SET imagen_src = _imagen_src
    WHERE cliente = _cliente;

    RAISE NOTICE 'La imagen del usuario % se ha actualizado correctamente', _cliente;
END;
$$;