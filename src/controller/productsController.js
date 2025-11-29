import {handleRequest} from "../util/controllerHelper.js";
import {
    changeProductQuantity,
    deleteProduct,
    getProductByCode,
    getProductsByFilter,
    getProductsBySearch,
    registerProduct,
    updateProduct
} from "../model/productsModel.js";

// Controlador para registrar un producto
export const registerProductHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden registrar productos.'
        });
    }

    const requiredFields = ['codigo', 'nombre', 'descripcion', 'precio', 'cantidad', 'imagen_url'];
    await handleRequest(req, res, requiredFields, registerProduct, {
        imageField: 'imagen_url', imageFolder: 'productos'
    }, 201);
};

// Controlador para actualizar un producto
export const updateProductHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden actualizar productos.'
        });
    }

    const requiredFields = ['id_producto', 'codigo', 'nombre', 'descripcion', 'precio', 'cantidad', 'imagen_url'];
    await handleRequest(req, res, requiredFields, updateProduct, {imageField: 'imagen_url', imageFolder: 'productos'});
};

// Controlador para eliminar un producto
export const deleteProductHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden eliminar productos.'
        });
    }

    const requiredFields = ['codigo'];
    await handleRequest(req, res, requiredFields, deleteProduct, {useParams: true, unwrapData: true});
};

// Controlador para cambiar la cantidad de un producto
export const changeProductQuantityHandler = async (req, res) => {
    const tipo = req.user.tipo_usuario

    if (tipo !== 'usuario') {
        return res.status(403).json({
            success: false,
            message: "Permisos necesarios",
            error: 'Acceso denegado. Solo los administradores pueden modificar productos.'
        });
    }

    const requiredFields = ['codigo', 'cantidad'];
    await handleRequest(req, res, requiredFields, changeProductQuantity);
};

// Controlador para obtener un producto
export const getProductByCodeHandler = async (req, res) => {
    const requiredFields = ['codigo'];
    await handleRequest(req, res, requiredFields, getProductByCode, {useParams: true, unwrapData: true});
};

// Controlador para filtrar productos
export const getProductsByFilterHandler = async (req, res) => {
    const requiredFields = ['columna_orden', 'orden', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getProductsByFilter);
};

// Controlador para buscar productos
export const getProductsBySearchHandler = async (req, res) => {
    const requiredFields = ['busqueda', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getProductsBySearch);
};