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

-- Tabla usuarios

CREATE TABLE IF NOT EXISTS usuarios
(
    id_usuario       SERIAL PRIMARY KEY,
    usuario          VARCHAR(20)                                  NOT NULL,
    nombre           VARCHAR(50)                                  NOT NULL,
    primer_apellido  VARCHAR(50)                                  NOT NULL,
    segundo_apellido VARCHAR(50)                                  NOT NULL,
    correo           VARCHAR(100)                                 NOT NULL,
    contrasena       TEXT      DEFAULT ''                         NOT NULL,
    rol              CHAR(1)   DEFAULT 'U' REFERENCES roles (rol) NOT NULL,
    fecha_registro   TIMESTAMP DEFAULT CURRENT_TIMESTAMP          NOT NULL,
    imagen_src       TEXT      DEFAULT ''                         NOT NULL,
    en_linea         BOOLEAN   DEFAULT FALSE                      NOT NULL,
    activo           BOOLEAN   DEFAULT TRUE                       NOT NULL
);

-- Índices de usuarios

CREATE INDEX idx_usuario_busqueda ON usuarios (
                                               usuario,
                                               nombre,
                                               primer_apellido,
                                               segundo_apellido,
                                               correo,
                                               fecha_registro,
                                               en_linea
    );

CREATE INDEX idx_usuario_activo ON usuarios (activo);

CREATE UNIQUE INDEX unique_usuario_usuario ON usuarios (usuario)
    WHERE
        activo = TRUE;

CREATE UNIQUE INDEX unique_usuario_correo ON usuarios (correo)
    WHERE
        activo = TRUE;

-- Vistas de usuarios

CREATE OR REPLACE VIEW vst_usuarios_general AS
SELECT u.usuario,
       TRIM(CONCAT(
               u.nombre,
               ' ',
               u.primer_apellido,
               ' ',
               u.segundo_apellido
            ))               AS nombre_completo,
       u.correo,
       r.nombre::VARCHAR(14) AS rol_usuario,
       u.fecha_registro,
       u.en_linea
FROM usuarios u
         LEFT JOIN roles r ON u.rol = r.rol
WHERE u.activo = TRUE;

CREATE OR REPLACE VIEW vst_usuarios AS
SELECT *
FROM usuarios
WHERE activo = TRUE;

-- Funciones de usuarios

CREATE OR REPLACE FUNCTION iniciar_sesion_usuarios(
    _usuario VARCHAR(20)
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
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    RETURN QUERY
        SELECT u.contrasena
        FROM vst_usuarios u
        WHERE u.usuario = _usuario;
END;
$$;

CREATE OR REPLACE FUNCTION consultar_usuario(
    _usuario VARCHAR(20)
)
    RETURNS TABLE
            (
                id_usuario       INT,
                usuario          VARCHAR(20),
                nombre           VARCHAR(50),
                primer_apellido  VARCHAR(50),
                segundo_apellido VARCHAR(50),
                correo           VARCHAR(100),
                contrasena       TEXT,
                rol              CHAR(1),
                fecha_registro   TIMESTAMP,
                imagen_src       TEXT,
                en_linea         BOOLEAN,
                activo           BOOLEAN
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    RETURN QUERY
        SELECT *
        FROM vst_usuarios u
        WHERE u.usuario = _usuario;
END;
$$;

CREATE OR REPLACE FUNCTION buscar_usuarios(
    _busqueda TEXT,
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total           BIGINT,
                usuario         VARCHAR(20),
                nombre_completo TEXT,
                correo          VARCHAR(100),
                rol_usuario     VARCHAR(14),
                fecha_registro  TIMESTAMP,
                en_linea        BOOLEAN
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
    FROM vst_usuarios_general u
    WHERE u.usuario ILIKE '%' || _busqueda || '%'
       OR u.nombre_completo ILIKE '%' || _busqueda || '%'
       OR u.correo ILIKE '%' || _busqueda || '%'
       OR u.rol_usuario ILIKE '%' || _busqueda || '%'
       OR u.fecha_registro::TEXT ILIKE '%' || _busqueda || '%';

    RETURN QUERY
        SELECT v_total,
               *
        FROM vst_usuarios_general u
        WHERE u.usuario ILIKE '%' || _busqueda || '%'
           OR u.nombre_completo ILIKE '%' || _busqueda || '%'
           OR u.correo ILIKE '%' || _busqueda || '%'
           OR u.rol_usuario ILIKE '%' || _busqueda || '%'
           OR u.fecha_registro::TEXT ILIKE '%' || _busqueda || '%'
        LIMIT _limit OFFSET _offset;
END;
$$;

CREATE OR REPLACE FUNCTION filtrar_usuarios(
    _columna_orden VARCHAR(15) DEFAULT 'nombre_completo',
    _orden VARCHAR(4) DEFAULT 'ASC',
    _limit INT DEFAULT 10,
    _offset INT DEFAULT 0
)
    RETURNS TABLE
            (
                total           BIGINT,
                usuario         VARCHAR(20),
                nombre_completo TEXT,
                correo          VARCHAR(100),
                rol_usuario     VARCHAR(14),
                fecha_registro  TIMESTAMP,
                en_linea        BOOLEAN
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
    FROM vst_usuarios_general;

    consulta := format('
            SELECT
                %L::BIGINT,
                *
            FROM
                vst_usuarios_general
            ORDER BY
                %I %s
            LIMIT %L
            OFFSET %L',
                       v_total, _columna_orden, _orden, _limit, _offset);

    RETURN QUERY EXECUTE consulta;
END;
$$;

-- Procedimientos de usuarios

CREATE OR REPLACE PROCEDURE registrar_usuario(
    _usuario VARCHAR(20),
    _nombre VARCHAR(50),
    _primer_apellido VARCHAR(50),
    _segundo_apellido VARCHAR(50),
    _correo VARCHAR(100),
    _rol CHAR(1) DEFAULT 'U'
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _nombre IS NULL OR TRIM(_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre es obligatorio';
    ELSIF _primer_apellido IS NULL OR TRIM(_primer_apellido) = '' THEN
        RAISE EXCEPTION 'El primer apellido es obligatorio';
    ELSIF _segundo_apellido IS NULL OR TRIM(_segundo_apellido) = '' THEN
        RAISE EXCEPTION 'El segundo apellido es obligatorio';
    ELSIF _correo IS NULL OR TRIM(_correo) = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_usuarios u WHERE u.usuario = _usuario;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El usuario ya esta registrado';
    END IF;

    IF _correo !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'El correo electrónico no tiene un formato válido';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_usuarios u WHERE u.correo = _correo;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El correo electrónico ya esta registrado';
    END IF;

    INSERT INTO usuarios (usuario, nombre, primer_apellido, segundo_apellido, correo, rol)
    VALUES (_usuario,
            _nombre,
            _primer_apellido,
            _segundo_apellido,
            LOWER(_correo),
            _rol);

    RAISE NOTICE 'El usuario % se ha registrado correctamente', _usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE actualizar_usuario(
    _id_usuario INT,
    _usuario VARCHAR(20),
    _nombre VARCHAR(50),
    _primer_apellido VARCHAR(50),
    _segundo_apellido VARCHAR(50),
    _correo VARCHAR(100)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _id_usuario IS NULL OR _id_usuario <= 0 THEN
        RAISE EXCEPTION 'El identificador del usuario es obligatorio';
    ELSIF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _nombre IS NULL OR TRIM(_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre es obligatorio';
    ELSIF _primer_apellido IS NULL OR TRIM(_primer_apellido) = '' THEN
        RAISE EXCEPTION 'El primer apellido es obligatorio';
    ELSIF _segundo_apellido IS NULL OR TRIM(_segundo_apellido) = '' THEN
        RAISE EXCEPTION 'El segundo apellido es obligatorio';
    ELSIF _correo IS NULL OR TRIM(_correo) = '' THEN
        RAISE EXCEPTION 'El correo electrónico es obligatorio';
    END IF;

    IF _correo !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'El correo electrónico no tiene un formato válido';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.id_usuario = _id_usuario;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_usuarios u WHERE u.usuario = _usuario AND u.id_usuario <> _id_usuario;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El usuario ya esta registrado';
    END IF;

    SELECT COUNT(*) INTO v_total FROM vst_usuarios u WHERE u.correo = _correo AND u.id_usuario <> _id_usuario;
    IF v_total > 0 THEN
        RAISE EXCEPTION 'El correo electrónico ya esta registrado';
    END IF;

    UPDATE
        usuarios
    SET usuario          = _usuario,
        nombre           = _nombre,
        primer_apellido  = _primer_apellido,
        segundo_apellido = _segundo_apellido,
        correo           = LOWER(_correo)
    WHERE id_usuario = _id_usuario;

    RAISE NOTICE 'El usuario % se ha actualizado correctamente', _usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE eliminar_usuario(
    _usuario VARCHAR(20)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario
      AND u.en_linea = FALSE;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe o esta siendo utilizado';
    END IF;

    IF (SELECT u.id_usuario
        FROM vst_usuarios u
        WHERE u.usuario = _usuario) = 1 THEN
        RAISE EXCEPTION 'No se puede eliminar el usuario administrador';
    END IF;

    UPDATE
        usuarios
    SET activo = FALSE
    WHERE usuario = _usuario;

    RAISE NOTICE 'El usuario % se ha eliminado correctamente', _usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_rol_usuario(
    _usuario VARCHAR(20),
    _rol CHAR(1)
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _rol IS NULL OR TRIM(_rol) = '' THEN
        RAISE EXCEPTION 'El rol es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario
      AND u.en_linea = FALSE;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe o esta siendo utilizado';
    END IF;

    UPDATE
        usuarios
    SET rol = _rol
    WHERE usuario = _usuario;

    RAISE NOTICE 'El usuario % se ha actualizado correctamente', _usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_contrasena_usuario(
    _usuario VARCHAR(20),
    _contrasena TEXT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _contrasena IS NULL OR TRIM(_contrasena) = '' THEN
        RAISE EXCEPTION 'La contraseña es obligatoria';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    UPDATE
        usuarios
    SET contrasena = _contrasena
    WHERE usuario = _usuario;
    RAISE NOTICE 'La contraseña del usuario % se ha actualizado correctamente', _usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_imagen_usuario(
    _usuario VARCHAR(20),
    _imagen_src TEXT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _imagen_src IS NULL OR TRIM(_imagen_src) = '' THEN
        RAISE EXCEPTION 'La imagen es obligatoria';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    UPDATE
        usuarios
    SET imagen_src = _imagen_src
    WHERE usuario = _usuario;

    RAISE NOTICE 'La imagen del usuario % se ha actualizado correctamente', _usuario;
END;
$$;

CREATE OR REPLACE PROCEDURE cambiar_sesion(
    _usuario VARCHAR(20),
    _en_linea BOOLEAN
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total INT;
BEGIN
    IF _usuario IS NULL OR TRIM(_usuario) = '' THEN
        RAISE EXCEPTION 'El usuario es obligatorio';
    ELSIF _en_linea IS NULL THEN
        RAISE EXCEPTION 'La sesión es obligatoria';
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM vst_usuarios u
    WHERE u.usuario = _usuario
      AND u.en_linea <> _en_linea;

    IF v_total = 0 THEN
        RAISE EXCEPTION 'El usuario no existe o se encuentra en el estado solicitado';
    END IF;

    UPDATE
        usuarios
    SET en_linea = _en_linea
    WHERE usuario = _usuario;

    IF _en_linea = FALSE THEN
        RAISE NOTICE 'El usuario % ha cerrado sesión correctamente', _usuario;
    ELSE
        RAISE NOTICE 'El usuario % ha iniciado sesión correctamente', _usuario;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE cerrar_sesiones()
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE
        usuarios
    SET en_linea = FALSE
    WHERE en_linea = TRUE;

    RAISE NOTICE 'Las sesiones se han cerrado correctamente';
END;
$$;

-- Default

INSERT INTO usuarios (usuario,
                      nombre,
                      primer_apellido,
                      segundo_apellido,
                      correo,
                      rol)
VALUES ('admin',
        'Administrador',
        '',
        '',
        '',
        'A');

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