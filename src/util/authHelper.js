import jwt from "jsonwebtoken";
import {config} from "dotenv";

// Cargar variables de entorno desde el archivo .env
config();

// Clave secreta para firmar los tokens JWT
const secretKey = process.env.JWT_SECRET;

// Función para generar un token JWT para un usuario dado
export function generateToken(usuario, tipo = "usuario", expiracion = process.env.JWT_EXPIRES) {
    const payload = {
        usuario_activo: usuario,
        tipo_usuario: tipo
    };

    return jwt.sign(payload, secretKey, {
        expiresIn: expiracion
    });
}

// Middleware para autenticar solicitudes usando JWT
export function authentication(req, res, next) {
    const token = req.headers["authorization"]?.split(" ")[1];

    try {
        req.user = jwt.verify(token, secretKey);
        next();
    } catch (error) {
        return res.status(403).json({
            success: false, message: "Error en la operación", error: "Token inválido o expirado"
        });
    }
}