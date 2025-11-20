import {executeQuery, executeStoredProcedure} from "../util/modelHelper.js";

// Modelo para registrar un producto
export const registerProduct = async (data) => {
    return executeStoredProcedure("registrar_producto", [data.codigo, data.nombre, data.descripcion, data.precio, data.cantidad, data.imagen_url]);
};

// Modelo para actualizar un producto
export const updateProduct = async (data) => {
    return executeStoredProcedure("actualizar_producto", [data.id_producto, data.codigo, data.nombre, data.descripcion, data.precio, data.cantidad, data.imagen_url]);
};

// Modelo para eliminar un producto
export const deleteProduct = async (codigo) => {
    return executeStoredProcedure("eliminar_producto", [codigo]);
};

// Modelo para cambiar la cantidad de un producto
export const changeProductQuantity = async (codigo, cantidad) => {
    return executeStoredProcedure("cambiar_cantidad_producto", [codigo, cantidad]);
};

// Modelo para obtener un producto por su código de producto
export const getProductByCode = async (codigo) => {
    const result = await executeQuery("consultar_producto", [codigo]);
    return result[0];
};

// Modelo para obtener todos los productos por filtro
export const getProductsByFilter = async (data) => {
    return executeQuery("filtrar_productos", [data.columna_orden, data.orden, data.limite, data.desplazamiento]);
};

// Modelo para obtener todos los productos por búsqueda
export const getProductsBySearch = async (data) => {
    return executeQuery("buscar_productos", [data.busqueda, data.limite, data.desplazamiento]);
};