// Controlador para servir la página de resultado
import {serveResultPage} from "../model/checkoutModel.js";

export const serveResultPageHandler = async (req, res) => {
    const result = await serveResultPage();

    if (result.success) {
        res.setHeader('Content-Type', 'text/html');
        res.send(result.data);
    } else {
        res.status(500).json({success: false, message: result.message, error: result.error});
    }
};