importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyAEbQCLSZOe8GxhO9gp_4G8T-wpdJEO7qg",
    appId: "1:704257001092:web:aeaefc19f6aa9adc8324d1",
    messagingSenderId: "704257001092",
    projectId: "imobareld",
    authDomain: "imobareld.firebaseapp.com",
    storageBucket: "imobareld.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log("[firebase-messaging-sw.js] Received background message ", payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: "/icons/Icon-192.png",
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
