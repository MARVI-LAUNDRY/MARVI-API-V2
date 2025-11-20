import {executeQuery, executeStoredProcedure} from "../util/modelHelper.js";
import {comparePassword} from "../util/bcryptHelper.js";
import {generateToken} from "../util/authHelper.js";
import {sendEmail} from "../util/nodemailerHelper.js";
import fs from "node:fs";

// Modelo para iniciar sesión de un usuario
export const loginUser = async (data) => {
    const password = await executeQuery("iniciar_sesion_usuarios", [data.usuario]);

    if (password[0].contrasena === '') return {
        success: true, data: {token: generateToken(data.usuario)}, message: "Inicio de sesión exitoso"
    }; else return await comparePassword(data.contrasena, password[0].contrasena) ? {
        success: true, data: {token: generateToken(data.usuario)}, message: "Inicio de sesión exitoso"
    } : {success: false, message: "Inicio de sesión fallido", error: "Usuario o contraseña incorrectos"};
};

// Modelo para cambiar la sesión de un usuario
export const changeUserSession = async (data) => {
    return executeStoredProcedure("cambiar_sesion", [data.usuario, data.en_linea]);
};

// Modelo para cerrar todas las sesiones de usuarios
export const logoutAllUsers = async () => {
    return executeStoredProcedure("cerrar_sesiones");
};

// Modelo para restablecer la contraseña de un usuario
export const resetUserPassword = async (usuario) => {
    try {
        // Verificar si el usuario existe
        const result = await executeQuery("consultar_usuario", [usuario]);

        // Si el usuario existe, enviar el correo de restablecimiento
        if (result.length > 0) {
            const template = fs.readFileSync("./templates/reset_password.html", "utf8");
            const url = `${process.env.PUBLIC_URL}:${process.env.PORT}/login/reset/password/${generateToken(result[0].usuario, 'usuario', '10m')}`;
            const htmlContent = template.replace("_link", url);

            const data = {
                destino: result[0].correo, asunto: "Restablecer contraseña", html: htmlContent,
            }

            if (await sendEmail(data)) return {
                success: true, data: [], message: "Correo de restablecimiento enviado"
            }; else return {
                success: false,
                message: "Error al enviar el correo de restablecimiento",
                error: "Error en el servidor de correo"
            };
        }
    } catch (error) {
        return {success: false, message: "Error al enviar el correo de restablecimiento", error: error.message};
    }
};

// Modelo para obtener un usuario por su correo electrónico
export const getClientByEmail = async (correo) => {
    const result = await executeQuery("consultar_cliente_por_correo", [correo]);
    return result[0];
};

// Modelo para iniciar sesión de un cliente
export const loginClient = async (data) => {
    const password = await executeQuery("iniciar_sesion_clientes", [data.cliente]);

    return await comparePassword(data.contrasena, password[0].contrasena) ? {
        success: true, data: {token: generateToken(data.cliente, 'cliente')}, message: "Inicio de sesión exitoso"
    } : {success: false, message: "Inicio de sesión fallido", error: "Usuario o contraseña incorrectos"};
};

// Modelo para restablecer la contraseña de un cliente
export const resetClientPassword = async (cliente) => {
    try {
        const template = fs.readFileSync("./templates/reset_password.html", "utf8");
        const url = `${process.env.PUBLIC_URL}:${process.env.PORT}/login/reset/password/${generateToken(cliente.cliente, 'cliente', '10m')}`;
        const htmlContent = template.replace("_link", url);

        const data = {
            destino: cliente.correo, asunto: "Restablecer contraseña", html: htmlContent,
        }

        if (await sendEmail(data)) return {
            success: true, data: [], message: "Correo de restablecimiento enviado"
        }; else return {
            success: false,
            message: "Error al enviar el correo de restablecimiento",
            error: "Error en el servidor de correo"
        };
    } catch (error) {
        return {success: false, message: "Error al enviar el correo de restablecimiento", error: error.message};
    }
};

// Verificar o crear usuario desde Google
export const googleAuth = async (googleData) => {
    try {
        // Buscar si el usuario ya existe
        const result = await executeQuery("consultar_cliente", [googleData.sub]);

        if (result.length > 0) {
            // Usuario existente
            return {
                success: true,
                data: {token: generateToken(googleData.sub, 'cliente')},
                message: "Inicio de sesión exitoso con Google"
            };
        }
    } catch (error) {
        // Si no existe, crear un nuevo usuario
        const result = await executeStoredProcedure("registrar_cliente", [googleData.sub, googleData.given_name, googleData.family_name, '', googleData.email, googleData.password, googleData.picture]);

        if (result.success) {
            const template = fs.readFileSync("./templates/welcome.html", "utf8");
            const htmlContent = template.replace("_name", googleData.given_name);

            const emailData = {
                destino: googleData.email, asunto: "¡Registro completo!", html: htmlContent,
            }

            if (await sendEmail(emailData)) return {
                success: true,
                data: {token: generateToken(googleData.sub, 'cliente')},
                message: "Cuenta creada e inicio de sesión exitoso con Google"
            }; else return {
                success: false,
                message: "Cuenta creada, pero no se pudo enviar el correo de bienvenida",
                error: "Error en el servidor de correo"
            };
        }
    }
};

// Modelo para servir la página de restablecimiento de contraseña
export const serveResetPasswordPage = async () => {
    try {
        const template = fs.readFileSync("./templates/reset_password_form.html", "utf8");
        const url = `${process.env.PUBLIC_URL}:${process.env.PORT}/img/`;
        return {
            success: true,
            data: template.replace("_href_i", url).replace("_href_l", url),
            message: "Página de restablecimiento servida"
        };
    } catch (error) {
        return {success: false, message: "Error al servir la página de restablecimiento", error: error.message};
    }
};