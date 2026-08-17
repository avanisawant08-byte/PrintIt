importScripts('https://www.gstatic.com/firebasejs/10.8.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.1/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyAqy84RsMk86a6boA-xi5ZNFHbhhLd5Cd8",
    authDomain: "printit-2ba1a.firebaseapp.com",
    projectId: "printit-2ba1a",
    storageBucket: "printit-2ba1a.firebasestorage.app",
    messagingSenderId: "374717568400",
    appId: "1:374717568400:web:20b913be55ae68a3354f15",
    measurementId: "G-3SQW12SP9E"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/favicon.ico',
        data: payload.data
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
