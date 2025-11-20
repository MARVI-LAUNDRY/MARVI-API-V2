import {executeQuery, executeStoredProcedure} from "../util/modelHelper.js";
import {createPaymentSession} from "../util/stripeHelper.js";

// Modelo para registrar un pedido
export const registerOrder = async (data) => {
    const result = await executeQuery("registrar_pedido", [data.cliente, JSON.stringify(data.productos), data.descuento]);
    const orderData = {
        order: result[0].folio,
        amount: Math.round(result[0].total * 100), // en centavos
        currency: "mxn",
        successUrl: `${process.env.PUBLIC_URL}:${process.env.PORT}/checkout/success`,
        cancelUrl: `${process.env.PUBLIC_URL}:${process.env.PORT}/checkout/cancel`
    }
    return await createPaymentSession(orderData)
};

// Modelo para actualizar un pedido
export const updateOrder = async (data) => {
    return executeStoredProcedure("actualizar_estado_pedido", [data.folio, data.estado]);
};

// Modelo para cancelar un pedido
export const cancelOrder = async (sheet) => {
    return executeStoredProcedure("cancelar_pedido", [sheet]);
};

// Modelo para obtener un pedido por su folio
export const getOrderBySheet = async (sheet) => {
    const result = await executeQuery("consultar_pedido", [sheet]);
    return result[0];
};

// Modelo para obtener los detalles de un pedido por su folio
export const getOrderDetailsBySheet = async (sheet) => {
    return executeQuery("consultar_detalles_pedido", [sheet]);
};

// Modelo para obtener todos los pedidos de un cliente
export const getOrdersByClient = async (cliente) => {
    return executeQuery("consultar_pedidos_cliente", [cliente]);
};

// Modelo para obtener todos los pedidos por filtro
export const getOrdersByFilter = async (data) => {
    return executeQuery("filtrar_pedidos", [data.columna_orden, data.orden, data.limite, data.desplazamiento]);
};

// Modelo para obtener todos los pedidos por búsqueda
export const getOrdersBySearch = async (data) => {
    return executeQuery("buscar_pedidos", [data.busqueda, data.limite, data.desplazamiento]);
};