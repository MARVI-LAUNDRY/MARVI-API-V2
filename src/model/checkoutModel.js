// Modelo para servir la página de resultado
import fs from "fs";

export const serveResultPage = async () => {
    try {
        const template = fs.readFileSync("./templates/checkout.html", "utf8");
        const url = `${process.env.PUBLIC_URL}:${process.env.PORT}/img/`;
        return {
            success: true,
            data: template.replace("_href_i", url).replace("_href_l", url),
            message: "Página de resultado servida"
        };
    } catch (error) {
        return {success: false, message: "Error al servir la página de resultado", error: error.message};
    }
};