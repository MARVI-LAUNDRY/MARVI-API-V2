import {executeQuery, executeStoredProcedure} from "../util/modelHelper.js";

// Modelo para registrar un usuario
export const registerUser = async (data) => {
    return executeStoredProcedure("registrar_usuario", [data.usuario, data.nombre, data.primer_apellido, data.segundo_apellido, data.correo, data.rol]);
};

// Modelo para actualizar un usuario
export const updateUser = async (data) => {
    return executeStoredProcedure("actualizar_usuario", [data.id_usuario, data.usuario, data.nombre, data.primer_apellido, data.segundo_apellido, data.correo]);
};

// Modelo para eliminar un usuario
export const deleteUser = async (usuario) => {
    return executeStoredProcedure("eliminar_usuario", [usuario]);
};

// Modelo para cambiar el rol de un usuario
export const changeUserRole = async (data) => {
    return executeStoredProcedure("cambiar_rol_usuario", [data.usuario, data.rol]);
};

// Modelo para cambiar la contraseña de un usuario
export const changeUserPassword = async (data) => {
    return executeStoredProcedure("cambiar_contrasena_usuario", [data.usuario, data.contrasena]);
};

// Modelo para actualizar la imagen de un usuario
export const changeUserImage = async (data) => {
    return executeStoredProcedure("cambiar_imagen_usuario", [data.usuario, data.imagen_src]);
};

// Modelo para obtener un usuario por su nombre de usuario
export const getUserByUsername = async (usuario) => {
    const result = await executeQuery("consultar_usuario", [usuario]);
    return result[0];
};

// Modelo para obtener todos los usuarios por filtro
export const getUsersByFilter = async (data) => {
    return executeQuery("filtrar_usuarios", [data.columna_orden, data.orden, data.limite, data.desplazamiento]);
};

// Modelo para obtener todos los usuarios por búsqueda
export const getUsersBySearch = async (data) => {
    return executeQuery("buscar_usuarios", [data.busqueda, data.limite, data.desplazamiento]);
};