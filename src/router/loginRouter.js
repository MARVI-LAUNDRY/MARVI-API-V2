import express from "express";
import {
    changeUserSessionHandler, googleAuthHandler, loginClientHandler, loginUserHandler, logoutAllUsersHandler,
    resetClientPasswordHandler, resetUserPasswordHandler, serveResetPasswordPageHandler
} from "../controller/loginController.js";
import {authentication} from "../util/authHelper.js";

// Crea nueva instancia de un router de express
const router = express.Router();

// Ruta para iniciar sesión de usuarios
router.post("/user", loginUserHandler);
// Ruta para cambiar la sesión de un usuario
router.put("/user/session", authentication, changeUserSessionHandler);
// Ruta para cerrar todas las sesiones de usuarios
router.post("/users/logout", authentication, logoutAllUsersHandler);
// Ruta para restablecer la contraseña de un usuario
router.post("/user/reset/password/:usuario", resetUserPasswordHandler);

// Ruta para iniciar sesión de un cliente
router.post("/client", loginClientHandler);
// Ruta para restablecer la contraseña de un cliente
router.post("/client/reset/password", resetClientPasswordHandler);

// Ruta para autenticar o registrar usuario desde Google
router.post("/google", googleAuthHandler);

// Ruta para servir la página de restablecimiento de contraseña
router.get("/reset/password/:token", serveResetPasswordPageHandler);

// Exporta el router
export default router;