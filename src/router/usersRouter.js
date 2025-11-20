import express from "express";
import {
    changeUserImageHandler,
    changeUserPasswordHandler,
    changeUserRoleHandler,
    deleteUserHandler,
    getUserByUsernameHandler,
    getUsersByFilterHandler,
    getUsersBySearchHandler,
    registerUserHandler,
    updateUserHandler
} from "../controller/usersController.js";
import {authentication} from "../util/authHelper.js";

// Crea nueva instancia de un router de express
const router = express.Router();

// Ruta para registrar usuarios
router.post("/", authentication, registerUserHandler);
// Ruta para actualizar usuarios
router.put("/", authentication, updateUserHandler);
// Ruta para eliminar usuarios
router.delete("/:usuario", authentication, deleteUserHandler);
// Ruta para cambiar el rol de un usuario
router.patch("/role", authentication, changeUserRoleHandler);
// Ruta para cambiar la contraseña de un usuario
router.patch("/password", authentication, changeUserPasswordHandler);
// Ruta para cambiar la imagen de perfil de un usuario
router.patch("/image", authentication, changeUserImageHandler);

// Ruta para obtener un usuario por su nombre de usuario
router.get("/:usuario", authentication, getUserByUsernameHandler);

// Ruta para filtrar usuarios
router.post("/filter", authentication, getUsersByFilterHandler);
// Ruta para buscar usuarios
router.post("/search", authentication, getUsersBySearchHandler);

// Exporta el router
export default router;