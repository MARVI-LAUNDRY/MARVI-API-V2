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