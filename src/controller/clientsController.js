import {handleRequest} from "../util/controllerHelper.js";
import {
    changeClientImage,
    changeClientPassword,
    deleteClient,
    getClientByUsername,
    getClientsByFilter,
    getClientsBySearch,
    registerClient,
    updateClient
} from "../model/clientsModel.js";

// Controlador para registrar un cliente
export const registerClientHandler = async (req, res) => {
    const requiredFields = ['cliente', 'nombre', 'primer_apellido', 'segundo_apellido', 'correo', 'contrasena', 'imagen_src', 'telefono', 'direccion'];
    await handleRequest(req, res, requiredFields, registerClient, {
        blank: true, passwordField: 'contrasena', imageField: 'imagen_src', imageFolder: 'clientes'
    }, 201);
};

// Controlador para actualizar un cliente
export const updateClientHandler = async (req, res) => {
    const requiredFields = ['id_cliente', 'cliente', 'nombre', 'primer_apellido', 'segundo_apellido', 'correo', 'telefono', 'direccion'];
    await handleRequest(req, res, requiredFields, updateClient, {blank: true});
};

// Controlador para eliminar un cliente
export const deleteClientHandler = async (req, res) => {
    const requiredFields = ['cliente'];
    await handleRequest(req, res, requiredFields, deleteClient, {useParams: true, unwrapData: true});
};

// Controlador para cambiar la contraseña de un cliente
export const changeClientPasswordHandler = async (req, res) => {
    const requiredFields = ['cliente', 'contrasena'];
    await handleRequest(req, res, requiredFields, changeClientPassword, {passwordField: 'contrasena'});
};

// Controlador para cambiar la imagen de un cliente
export const changeClientImageHandler = async (req, res) => {
    const requiredFields = ['cliente', 'imagen_src'];
    await handleRequest(req, res, requiredFields, changeClientImage, {
        imageField: 'imagen_src', imageFolder: 'clientes'
    });
};

// Controlador para obtener un cliente
export const getClientByUsernameHandler = async (req, res) => {
    const requiredFields = ['cliente'];
    await handleRequest(req, res, requiredFields, getClientByUsername, {useParams: true, unwrapData: true});
};

// Controlador para filtrar clientes
export const getClientsByFilterHandler = async (req, res) => {
    const requiredFields = ['columna_orden', 'orden', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getClientsByFilter);
};

// Controlador para buscar clientes
export const getClientsBySearchHandler = async (req, res) => {
    const requiredFields = ['busqueda', 'limite', 'desplazamiento'];
    await handleRequest(req, res, requiredFields, getClientsBySearch);
};