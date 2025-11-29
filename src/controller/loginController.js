import {handleRequest} from "../util/controllerHelper.js";
import {
    changeUserSession,
    getClientByEmail,
    googleAuth,
    loginClient,
    loginUser,
    logoutAllUsers,
    resetClientPassword,
    resetUserPassword,
    serveResetPasswordPage
} from "../model/loginModel.js";

// Controlador para iniciar sesión de un usuario
export const loginUserHandler = async (req, res) => {
    const requiredFields = ['usuario', 'contrasena'];
    await handleRequest(req, res, requiredFields, loginUser, {blank: true});
};

// Controlador para cambiar la sesión de un usuario
export const changeUserSessionHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar sesiones.'
        });
    }

    const requiredFields = ['usuario', 'en_linea'];
    await handleRequest(req, res, requiredFields, changeUserSession);
};

// Controlador para cerrar todas las sesiones de usuarios
export const logoutAllUsersHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar sesiones.'
        });
    }

    await handleRequest(req, res, [], logoutAllUsers);
};

// Controlador para restablecer la contraseña de un usuario
export const resetUserPasswordHandler = async (req, res) => {
    const requiredFields = ['usuario'];
    await handleRequest(req, res, requiredFields, resetUserPassword, {useParams: true, unwrapData: true});
};

// Controlador para iniciar sesión de un cliente
export const loginClientHandler = async (req, res) => {
    try {
        const requiredFields = ['cliente', 'contrasena'];
        const correo = req.body.correo.trim();
        const result = await getClientByEmail(correo);
        if (result.cliente) req.body.cliente = result.cliente
        await handleRequest(req, res, requiredFields, loginClient);
    } catch (error) {
        return res.status(403).json({
            success: false,
            message: "Inicio de sesión fallido",
            error: "Usuario o contraseña incorrectos"
        })
    }
};

// Controlador para restablecer la contraseña de un cliente
export const resetClientPasswordHandler = async (req, res) => {
    try {
        const requiredFields = ['cliente'];
        const correo = req.body.correo.trim();
        const result = await getClientByEmail(correo);
        if (result.cliente) req.body.cliente = result
        await handleRequest(req, res, requiredFields, resetClientPassword, {unwrapData: true});
    } catch (error) {
        return res.status(403).json({
            success: false,
            message: "Restablecimiento de contraseña fallido",
            error: error.message
        })
    }
};

// Controlador para autenticar o registrar usuario desde Google
export const googleAuthHandler = async (req, res) => {
    const requiredFields = ['credencial'];
    await handleRequest(req, res, requiredFields, googleAuth, {blank: true, unwrapData: true, google: true});
};

// Controlador para servir la página de restablecimiento de contraseña
export const serveResetPasswordPageHandler = async (req, res) => {
    const result = await serveResetPasswordPage();

    if (result.success) {
        res.setHeader('Content-Type', 'text/html');
        res.send(result.data);
    } else {
        res.status(500).json({success: false, message: result.message, error: result.error});
    }
};