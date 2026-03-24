// ══ REZI — Service Worker Firebase Cloud Messaging ══
// Version 2.0 — Notifications push en arrière-plan

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAkcUsXXjsGjrbwO-4YZxMj0UAmSpIBBHc",
  authDomain: "rezi-ci.firebaseapp.com",
  projectId: "rezi-ci",
  storageBucket: "rezi-ci.firebasestorage.app",
  messagingSenderId: "288685585486",
  appId: "1:288685585486:web:6a97f8db4a315a28967f1f"
});

const messaging = firebase.messaging();

// Notifications reçues en arrière-plan
messaging.onBackgroundMessage((payload) => {
  console.log('🔔 REZI Notification background:', payload);

  const { title, body, icon, image } = payload.notification || {};
  const data = payload.data || {};

  const notificationOptions = {
    body: body || 'Vous avez une nouvelle notification REZI',
    icon: icon || '/icons/icon-192.png',
    image: image,
    badge: '/icons/badge-72.png',
    tag: data.type || 'rezi-notif',
    data: data,
    actions: [
      { action: 'open', title: '👁️ Voir' },
      { action: 'dismiss', title: '✕ Fermer' }
    ],
    vibrate: [200, 100, 200],
    requireInteraction: false
  };

  self.registration.showNotification(
    title || '🏠 REZI',
    notificationOptions
  );
});

// Clic sur la notification
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};

  let url = 'https://garo21225.github.io/REZI/';

  if(data.type === 'reservation_confirmee' || data.reservation_id) {
    url += '#reservations';
  } else if(data.type === 'nouveau_message' || data.conversation_id) {
    url += '#messages';
  } else if(data.residence_id) {
    url += `#residence-${data.residence_id}`;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for(const client of clientList) {
        if(client.url.includes('garo21225.github.io/REZI') && 'focus' in client) {
          client.postMessage({ type: 'NOTIFICATION_CLICK', data });
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })
  );
});

// Cache stratégie pour PWA
const CACHE_NAME = 'rezi-v1';
const urlsToCache = ['/REZI/', '/REZI/index.html', '/REZI/manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(urlsToCache).catch(() => {}))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});
