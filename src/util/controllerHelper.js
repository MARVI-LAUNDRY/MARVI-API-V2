import {hashPassword} from "./bcryptHelper.js";
import {OAuth2Client} from 'google-auth-library';
import {config} from "dotenv";
import {uploadToCloudinary} from "./cloudinaryHelper.js";

config();

const verifyGoogleToken = async (idToken) => {
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

    // Verificar el token de ID de Google
    const ticket = await client.verifyIdToken({
        idToken, audience: process.env.GOOGLE_CLIENT_ID,
    });

    // Obtener la carga útil del token
    const payload = ticket.getPayload();
    payload.password = await hashPassword(payload.sub);

    return payload;
}

export const handleRequest = async (req, res, requiredFields, modelFunction, options = {}, statusCode = 200) => {
    try {
        // Determinar fuente de datos (params o body)
        const source = options.useParams ? req.params : req.body;

        // Filtrar el campo de imagen de los campos requeridos para la validación
        const fieldsToValidate = requiredFields.filter(field =>
            !(options.imageField && field === options.imageField)
        );

        // Validar campos requeridos
        const missingFields = fieldsToValidate.filter(field =>
            source[field] === undefined ||
            source[field] === null ||
            (!options.blank && source[field] === '')
        );

        // Sí faltan campos, enviar respuesta de error
        if (missingFields.length > 0) {
            return res.status(400).json({
                success: false, message: `Faltan campos requeridos: ${missingFields.join(', ')}`
            });
        }

        // Manejar autenticación de Google si se especifica
        if (options.google) {
            // Verificar token de Google
            const googleData = await verifyGoogleToken(source['credencial']);
            // Ejecutar función del modelo
            const result = await modelFunction(googleData);

            // Enviar respuesta exitosa
            return res.status(statusCode).json(result);
        }

        // Limpiar y preparar datos
        const data = {};
        for (const field of requiredFields) {
            const value = source[field];

            // Si el campo es contraseña, encriptarla
            if (options.passwordField && field === options.passwordField) {
                data[field] = await hashPassword(value);
            } else {
                data[field] = typeof value === 'string' ? value.trim() : value;
            }
        }

        // Manejar subida de imagen si existe
        if (options.imageField && req.file) {
            data[options.imageField] = await uploadToCloudinary(req.file, options.imageFolder);
        }

        // Ejecutar función del modelo
        const result = await modelFunction(options.unwrapData ? data[requiredFields[0]] : data);

        // Enviar respuesta exitosa
        return res.status(statusCode).json(result);
    } catch (error) {
        // Manejar errores y enviar respuesta de error
        return res.status(500).json({
            success: false, message: "Error en la operación", error: error.message
        });
    }
};