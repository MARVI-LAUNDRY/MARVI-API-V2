import {executeQuery, executeStoredProcedure} from "../util/modelHelper.js";
import fs from "node:fs";
import {sendEmail} from "../util/nodemailerHelper.js";

// Modelo para registrar un cliente
export const registerClient = async (data) => {
    const result = await executeStoredProcedure("registrar_cliente", [data.cliente, data.nombre, data.primer_apellido, data.segundo_apellido, data.correo, data.contrasena, data.imagen_src, data.telefono, data.direccion]);

    if (result.success) {
        const template = fs.readFileSync("./templates/welcome.html", "utf8");
        const htmlContent = template.replace("_name", data.nombre);

        const emailData = {
            destino: data.correo, asunto: "¡Registro completo!", html: htmlContent,
        }

        if (await sendEmail(emailData)) return result; else return {
            success: false,
            message: "Cuenta creada, pero no se pudo enviar el correo de bienvenida",
            error: "Error en el servidor de correo"
        };
    }
};

// Modelo para actualizar un cliente
export const updateClient = async (data) => {
    return executeStoredProcedure("actualizar_cliente", [data.id_cliente, data.cliente, data.nombre, data.primer_apellido, data.segundo_apellido, data.correo, data.telefono, data.direccion]);
};

// Modelo para eliminar un cliente
export const deleteClient = async (cliente) => {
    return executeStoredProcedure("eliminar_cliente", [cliente]);
};

// Modelo para cambiar la contraseña de un cliente
export const changeClientPassword = async (data) => {
    return executeStoredProcedure("cambiar_contrasena_cliente", [data.cliente, data.contrasena]);
};

// Modelo para actualizar la imagen de un cliente
export const changeClientImage = async (data) => {
    return executeStoredProcedure("cambiar_imagen_cliente", [data.cliente, data.imagen_src]);
};

// Modelo para obtener un usuario por su nombre de usuario
export const getClientByUsername = async (cliente) => {
    const result = await executeQuery("consultar_cliente", [cliente]);
    return result[0];
};

// Modelo para obtener todos los clientes por filtro
export const getClientsByFilter = async (data) => {
    return executeQuery("filtrar_clientes", [data.columna_orden, data.orden, data.limite, data.desplazamiento]);
};

// Modelo para obtener todos los clientes por búsqueda
export const getClientsBySearch = async (data) => {
    return executeQuery("buscar_clientes", [data.busqueda, data.limite, data.desplazamiento]);
};