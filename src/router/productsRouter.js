import express from "express";
import {
    changeProductQuantityHandler,
    deleteProductHandler,
    getProductByCodeHandler,
    getProductsByFilterHandler,
    getProductsBySearchHandler,
    registerProductHandler,
    updateProductHandler
} from "../controller/productsController.js";
import {authentication} from "../util/authHelper.js";
import {upload} from "../util/cloudinaryHelper.js";

// Crea nueva instancia de un router de express
const router = express.Router();

// Ruta para registrar productos
router.post("/", authentication, upload.single('imagen_url'), registerProductHandler);
// Ruta para actualizar productos
router.put("/", authentication, upload.single('imagen_url'), updateProductHandler);
// Ruta para eliminar productos
router.delete("/:codigo", authentication, deleteProductHandler);
// Ruta para cambiar la cantidad de un producto
router.patch("/quantity", authentication, changeProductQuantityHandler);

// Ruta para obtener un producto por su nombre de producto
router.get("/:codigo", authentication, getProductByCodeHandler);

// Ruta para filtrar productos
router.post("/filter", authentication, getProductsByFilterHandler);
// Ruta para buscar productos
router.post("/search", authentication, getProductsBySearchHandler);

// Exporta el router
export default router;