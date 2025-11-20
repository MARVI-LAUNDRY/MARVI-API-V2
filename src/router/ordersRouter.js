import express from "express";
import {
    cancelOrderHandler,
    getOrderBySheetHandler,
    getOrderDetailsBySheetHandler,
    getOrdersByClientHandler,
    getOrdersByFilterHandler,
    getOrdersBySearchHandler,
    registerOrderHandler,
    updateOrderHandler
} from "../controller/ordersController.js";
import {authentication} from "../util/authHelper.js";

// Crea nueva instancia de un router de express
const router = express.Router();

// Ruta para registrar pedidos
router.post("/", authentication, registerOrderHandler);
// Ruta para actualizar pedidos
router.put("/", authentication, updateOrderHandler);
// Ruta para cancelar pedidos
router.delete("/:folio", authentication, cancelOrderHandler);

// Ruta para obtener un pedido por su folio
router.get("/:folio", authentication, getOrderBySheetHandler);
// Ruta para obtener los detalles de un pedido por su folio
router.get("/details/:folio", authentication, getOrderDetailsBySheetHandler);

// Ruta para obtener pedidos de un cliente
router.get("/client/:cliente", authentication, getOrdersByClientHandler);
// Ruta para filtrar pedidos
router.post("/filter", authentication, getOrdersByFilterHandler);
// Ruta para buscar pedidos
router.post("/search", authentication, getOrdersBySearchHandler);

// Exporta el router
export default router;