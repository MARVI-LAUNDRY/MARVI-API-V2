import {handleRequest} from "../util/controllerHelper.js";
import {
    cancelOrder,
    getOrderBySheet,
    getOrderDetailsBySheet,
    getOrdersByClient,
    getOrdersByFilter,
    getOrdersBySearch,
    registerOrder,
    updateOrder
} from "../model/ordersModel.js";

// Controlador para registrar un pedido
export const registerOrderHandler = async (req, res) => {
    const requiredFields = ['cliente', 'productos', 'descuento'];
    await handleRequest(req, res, requiredFields, registerOrder, {}, 201);
};

// Controlador para actualizar un pedido
export const updateOrderHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar pedidos.'
        });
    }

    const requiredFields = ['folio', 'estado'];
    await handleRequest(req, res, requiredFields, updateOrder);
};

// Controlador para cancelar un pedido
export const cancelOrderHandler = async (req, res) => {
    const requiredFields = ['folio'];
    await handleRequest(req, res, requiredFields, cancelOrder, {useParams: true, unwrapData: true});
};

// Controlador para obtener un pedido
export const getOrderBySheetHandler = async (req, res) => {
    const requiredFields = ['folio'];
    await handleRequest(req, res, requiredFields, getOrderBySheet, {useParams: true, unwrapData: true});
};

// Controlador para obtener los detalles de un pedido
export const getOrderDetailsBySheetHandler = async (req, res) => {
    const requiredFields = ['folio'];
    await handleRequest(req, res, requiredFields, getOrderDetailsBySheet, {useParams: true, unwrapData: true});
};

// Controlador para obtener pedidos de un cliente
export const getOrdersByClientHandler = async (req, res) => {
    const requiredFields = ['cliente'];
    await handleRequest(req, res, requiredFields, getOrdersByClient, {useParams: true, unwrapData: true});
};

// Controlador para filtrar pedidos
export const getOrdersByFilterHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden ver los pedidos.'
        });
    }

    const requiredFields = ['columna_orden', 'orden', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getOrdersByFilter);
};

// Controlador para buscar pedidos
export const getOrdersBySearchHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden ver los pedidos.'
        });
    }

    const requiredFields = ['busqueda', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getOrdersBySearch);
};