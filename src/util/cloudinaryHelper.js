import cloudinary from '../config/cloudinary.js';
import multer from 'multer';

// Configurar multer para usar memoria
const storage = multer.memoryStorage();
export const upload = multer({storage});

// Función para subir imagen a Cloudinary
export const uploadToCloudinary = async (file, folder) => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream({
            folder: folder, resource_type: 'image', transformation: [{
                width: 500, height: 500, crop: 'fill', gravity: 'center'
            }, {
                quality: 'auto', fetch_format: 'auto'
            }]
        }, (error, result) => {
            if (error) reject(error); else resolve(result.secure_url);
        });
        uploadStream.end(file.buffer);
    });
};

/* Función para eliminar imagen de Cloudinary
export const deleteFromCloudinary = async (imageUrl) => {
    try {
        const urlParts = imageUrl.split('/');
        const fileName = urlParts[urlParts.length - 1].split('.')[0];
        const folder = urlParts[urlParts.length - 2];
        const publicId = `${folder}/${fileName}`;

        return await cloudinary.uploader.destroy(publicId);
    } catch (error) {
        console.error('Error al eliminar imagen:', error);
        throw new Error(`Error al eliminar imagen: ${error.message}`);
    }
}; */