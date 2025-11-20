import express from "express";
import {
    changeClientImageHandler,
    changeClientPasswordHandler,
    deleteClientHandler,
    getClientByUsernameHandler,
    getClientsByFilterHandler,
    getClientsBySearchHandler,
    registerClientHandler,
    updateClientHandler
} from "../controller/clientsController.js";
import {authentication} from "../util/authHelper.js";
import {upload} from "../util/cloudinaryHelper.js";

const router = express.Router();

// Ruta para registrar clientes
router.post("/", upload.single('imagen_src'), registerClientHandler);
// Ruta para actualizar clientes
router.put("/", authentication, updateClientHandler);
// Ruta para eliminar clientes
router.delete("/:cliente", authentication, deleteClientHandler);
// Ruta para cambiar la contraseña de un cliente
router.patch("/password", authentication, changeClientPasswordHandler);
// Ruta para cambiar la imagen de perfil de un cliente
router.patch("/image", authentication, upload.single('imagen_src'), changeClientImageHandler);

// Ruta para obtener un cliente por su nombre de cliente
router.get("/:cliente", authentication, getClientByUsernameHandler);

// Ruta para filtrar clientes
router.post("/filter", authentication, getClientsByFilterHandler);
// Ruta para buscar clientes
router.post("/search", authentication, getClientsBySearchHandler);

export default router;