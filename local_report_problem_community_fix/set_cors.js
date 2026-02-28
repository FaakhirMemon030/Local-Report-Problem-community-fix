// set_cors.js
const { Storage } = require('@google-cloud/storage');

// service-account.json ka path aur bucket ka naam
const storage = new Storage({ keyFilename: 'service-account.json' });
const bucketName = 'lrpcf-1502a.firebasestorage.app';

async function setCors() {
    await storage.bucket(bucketName).setCorsConfiguration([
        {
            maxAgeSeconds: 3600,
            method: ['GET', 'HEAD', 'PUT', 'POST', 'DELETE'],
            origin: ['*'],
            responseHeader: ['*'],
        },
    ]);
    console.log('✅ CORS configuration set successfully on ' + bucketName);
}

setCors().catch(console.error);
