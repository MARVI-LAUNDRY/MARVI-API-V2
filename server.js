import express from "express";
import cors from "cors";
import path from "path";
import {fileURLToPath} from "url";
import {config} from "dotenv";
import swaggerUi from "swagger-ui-express";
import swaggerDocument from "./src/swagger/swagger-output.json" with {type: "json"};

import usersRouter from "./src/router/usersRouter.js";
import clientsRouter from "./src/router/clientsRouter.js";
import productsRouter from "./src/router/productsRouter.js";
import loginRouter from "./src/router/loginRouter.js";
import ordersRouter from "./src/router/ordersRouter.js";
import checkoutRouter from "./src/router/checkoutRouter.js";
import getIPAddress from "./src/util/ipHelper.js";
import bodyParser from "express";
import {stripeWebhook} from "./src/util/stripeHelper.js";

// Obtener __dirname en ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

config();

const PORT = process.env.PORT || 3000;
const app = express();

// Middlewares
app.use(cors());
app.use("/webhook", bodyParser.raw({type: "application/json"}), stripeWebhook)
app.use(express.json());

// Servir archivos estáticos desde la carpeta 'public'
app.use(express.static(path.join(__dirname, 'public')));

// Rutas de API
app.use("/users", usersRouter);
app.use("/clients", clientsRouter);
app.use("/products", productsRouter);
app.use("/login", loginRouter);
app.use("/orders", ordersRouter);
app.use("/checkout", checkoutRouter);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.listen(PORT, "0.0.0.0", () => {
    console.debug(`Servidor iniciado en ${getIPAddress()}:${PORT}`);
});