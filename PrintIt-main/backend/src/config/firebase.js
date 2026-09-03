const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');

let app;

try {
    const serviceAccount = require('./serviceAccountKey.json'); // Download from Firebase Console
    app = initializeApp({
        credential: cert(serviceAccount),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app'
    });
} catch (error) {
    console.warn("⚠️ Firebase Admin initialization: 'serviceAccountKey.json' not found. Initializing with projectId for Google Login token verification.");
    app = initializeApp({
        projectId: 'printit-4d823',
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app'
    });
}

module.exports = { app, getAuth, getMessaging, getStorage };
