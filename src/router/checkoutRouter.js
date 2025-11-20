// Ruta para servir la página de restablecimiento de contraseña
import {serveResultPageHandler} from "../controller/checkoutController.js";
import express from "express";

// Crea nueva instancia de un router de express
const router = express.Router();

router.get("/:status", serveResultPageHandler);

export default router;