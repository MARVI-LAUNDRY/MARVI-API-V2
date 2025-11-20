import os from "os";

const getIPAddress = () => {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const face of interfaces[name]) {
            if (face.family === "IPv4" && !face.internal) {
                return face.address;
            }
        }
    }
    return "localhost";
};

export default getIPAddress;