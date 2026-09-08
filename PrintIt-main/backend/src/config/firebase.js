const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');

let app;

try {
    let serviceAccount = null;
    const localKeyPath = path.resolve(__dirname, 'serviceAccountKey.json');

    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
        serviceAccount = raw.startsWith('{') ? JSON.parse(raw) : JSON.parse(Buffer.from(raw, 'base64').toString('utf8'));
    } else if (fs.existsSync(localKeyPath)) {
        const fileContent = fs.readFileSync(localKeyPath, 'utf8');
        serviceAccount = JSON.parse(fileContent);
    }

    if (serviceAccount && serviceAccount.private_key) {
        app = initializeApp({
            credential: cert(serviceAccount),
            storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app'
        });
        console.log("✅ Firebase Admin initialized with service account credentials.");
    } else {
        throw new Error("No service account credentials provided. Falling back to project ID initialization.");
    }
} catch (error) {
    console.warn("⚠️ Firebase Admin initialization with service account not configured:", error.message);
    app = initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'printit-4d823',
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app'
    });
}

module.exports = { app, getAuth, getMessaging, getStorage };
