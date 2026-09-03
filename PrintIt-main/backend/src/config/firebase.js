const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');

let app;

try {
    let serviceAccount;
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
        serviceAccount = raw.startsWith('{') ? JSON.parse(raw) : JSON.parse(Buffer.from(raw, 'base64').toString('utf8'));
    } else {
        serviceAccount = require('./serviceAccountKey.json');
    }
    app = initializeApp({
        credential: cert(serviceAccount),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app'
    });
    console.log("✅ Firebase Admin initialized with service account credentials.");
} catch (error) {
    console.warn("⚠️ Firebase Admin initialization with service account failed or not found:", error.message);
    app = initializeApp({
        projectId: 'printit-4d823',
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app'
    });
}

module.exports = { app, getAuth, getMessaging, getStorage };
