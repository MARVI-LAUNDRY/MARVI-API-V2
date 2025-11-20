import {
    registerUser,
    updateUser,
    deleteUser,
    changeUserRole,
    changeUserPassword,
    getUserByUsername,
    getUsersByFilter,
    getUsersBySearch,
    changeUserImage
} from "../model/usersModel.js";
import {handleRequest} from "../util/controllerHelper.js";

// Controlador para registrar un usuario
export const registerUserHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden registrar usuarios.'
        });
    }

    const requiredFields = ['usuario', 'nombre', 'primer_apellido', 'segundo_apellido', 'correo', 'rol'];
    await handleRequest(req, res, requiredFields, registerUser, {}, 201);
};

// Controlador para actualizar un usuario
export const updateUserHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden actualizar usuarios.'
        });
    }

    const requiredFields = ['id_usuario', 'usuario', 'nombre', 'primer_apellido', 'segundo_apellido', 'correo'];
    await handleRequest(req, res, requiredFields, updateUser);
};

// Controlador para eliminar un usuario
export const deleteUserHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden eliminar usuarios.'
        });
    }

    const requiredFields = ['usuario'];
    await handleRequest(req, res, requiredFields, deleteUser, {useParams: true, unwrapData: true});
};

// Controlador para cambiar el rol de un usuario
export const changeUserRoleHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar usuarios.'
        });
    }

    const requiredFields = ['usuario', 'rol'];
    await handleRequest(req, res, requiredFields, changeUserRole);
};

// Controlador para cambiar la contraseña de un usuario
export const changeUserPasswordHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar usuarios.'
        });
    }

    const requiredFields = ['usuario', 'contrasena'];
    await handleRequest(req, res, requiredFields, changeUserPassword, {passwordField: 'contrasena'});
};

// Controlador para cambiar la imagen de un usuario
export const changeUserImageHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar usuarios.'
        });
    }

    const requiredFields = ['usuario', 'imagen_src'];
    await handleRequest(req, res, requiredFields, changeUserImage);
};

// Controlador para obtener un usuario
export const getUserByUsernameHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden ver los usuarios.'
        });
    }

    const requiredFields = ['usuario'];
    await handleRequest(req, res, requiredFields, getUserByUsername, {useParams: true, unwrapData: true});
};

// Controlador para filtrar usuarios
export const getUsersByFilterHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden ver los usuarios.'
        });
    }

    const requiredFields = ['columna_orden', 'orden', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getUsersByFilter);
};

// Controlador para buscar usuarios
export const getUsersBySearchHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden ver los usuarios.'
        });
    }

    const requiredFields = ['busqueda', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getUsersBySearch);
};