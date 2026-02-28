const { Storage } = require('@google-cloud/storage');

const storage = new Storage({ keyFilename: 'service-account.json' });

async function trySetCors(bucketName) {
    console.log(`Trying bucket: ${bucketName}...`);
    try {
        await storage.bucket(bucketName).setCorsConfiguration([
            {
                maxAgeSeconds: 3600,
                method: ['GET', 'HEAD', 'PUT', 'POST', 'DELETE'],
                origin: ['*'],
                responseHeader: ['*'],
            },
        ]);
        console.log(`✅ Success! CORS set on ${bucketName}`);
        return true;
    } catch (err) {
        console.error(`❌ Failed on ${bucketName}: ${err.message}`);
        return false;
    }
}

async function run() {
    const projectID = 'lrpcf-1502a';
    const names = [
        `${projectID}.appspot.com`,
        `${projectID}.firebasestorage.app`,
        projectID
    ];

    for (const name of names) {
        if (await trySetCors(name)) {
            console.log('\n🌟 Storage CORS is now FIXED! Please refresh your web app.');
            return;
        }
    }
}

run().catch(console.error);
