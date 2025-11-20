import {config} from "dotenv";
import pkg from "pg";

config();

const {Pool} = pkg;

const pool = new Pool({
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

pool.on("connect", () => {
    console.log("Conectado a la base de datos");
});

pool.on("error", (err) => {
    console.error("Error en la conexión a la base de datos:", err);
});

export default pool;