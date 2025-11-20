import pool from "../config/database.js";

// Función auxiliar para ejecutar procedimientos almacenados con captura de NOTICE
export const executeStoredProcedure = async (procedureName, params = []) => {
    // Obtener una conexión del pool
    const client = await pool.connect();
    let capturedNotice = null;

    // Listener para capturar mensajes NOTICE
    const noticeHandler = (msg) => {
        capturedNotice = msg.message;
    };
    client.on("notice", noticeHandler);

    try {
        // Ejecutar el procedimiento almacenado
        const response = await client.query(`CALL ${procedureName}(${params.map((_, i) => `$${i + 1}`).join(", ")});`, params);

        // Retornar el resultado junto con el mensaje NOTICE capturado
        return {
            success: true, data: response.rows, message: capturedNotice
        };
    } finally {
        // Limpiar el listener y liberar la conexión
        client.removeListener("notice", noticeHandler);
        client.release();
    }
};

// Función auxiliar para ejecutar funciones SELECT
export const executeQuery = async (functionName, params = []) => {
    // Obtener una conexión del pool
    const client = await pool.connect();

    try {
        // Ejecutar la función SELECT
        const placeholders = params.map((_, i) => `$${i + 1}`).join(", ");
        const response = await client.query(`SELECT *
                                             FROM ${functionName}(${placeholders});`, params);

        // Retornar las filas obtenidas
        return response.rows;
    } finally {
        // Liberar la conexión
        client.release();
    }
};