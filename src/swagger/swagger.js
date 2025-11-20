import swaggerAutogen from 'swagger-autogen';

const doc = {
    info: {
        title: 'MARVI API', description: 'Documentación generada automáticamente para el API de MARVI'
    }, host: 'localhost:3000', schemes: ['http']
};

const outputFile = './swagger-output.json';
const endpointsFiles = ['../../server.js'];

swaggerAutogen(outputFile, endpointsFiles, doc);