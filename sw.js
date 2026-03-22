// ══════════════════════════════════════════════════════════════
// REZI — Service Worker v2.0 + Firebase Cloud Messaging
// ══════════════════════════════════════════════════════════════
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

const CACHE_NAME = 'rezi-v2.0.0';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
];

// ── Firebase config (remplacer par vos valeurs Firebase Console) ──
const FIREBASE_CONFIG = {
  apiKey:            "VOTRE_API_KEY",
  authDomain:        "votre-projet.firebaseapp.com",
  projectId:         "votre-projet",
  storageBucket:     "votre-projet.appspot.com",
  messagingSenderId: "VOTRE_SENDER_ID",
  appId:             "VOTRE_APP_ID"
};

firebase.initializeApp(FIREBASE_CONFIG);
const messaging = firebase.messaging();

// ── Réception messages en arrière-plan ──
messaging.onBackgroundMessage(payload => {
  const { title, body, icon, tag, data } = payload.notification || {};
  const notifData = payload.data || {};

  self.registration.showNotification(title || '🏠 REZI', {
    body:    body    || 'Vous avez une nouvelle notification',
    icon:    icon    || '/icons/icon-192.png',
    badge:              '/icons/icon-72.png',
    tag:     tag     || 'rezi-notif-' + Date.now(),
    vibrate: [200, 100, 200],
    data:    { url: notifData.url || '/', ...notifData },
    actions: [
      { action: 'voir',    title: '👁️ Voir'    },
      { action: 'ignorer', title: '✕ Ignorer'  }
    ]
  });
});

// ── Clic sur notification ──
self.addEventListener('notificationclick', event => {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  if(event.action === 'voir' || !event.action) {
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clientList => {
        // Si l'app est déjà ouverte, focus + navigation
        for(const client of clientList) {
          if('focus' in client) {
            client.focus();
            client.postMessage({ type: 'NOTIFICATION_CLICK', url, data: event.notification.data });
            return;
          }
        }
        // Sinon ouvrir une nouvelle fenêtre
        return clients.openWindow(url);
      })
    );
  }
});

// ── Installation ──
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache =>
      cache.addAll(STATIC_ASSETS).catch(err => console.warn('[SW] Cache partiel:', err))
    )
  );
  self.skipWaiting();
});

// ── Activation ──
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// ── Fetch : Network First API, Cache First assets ──
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if(url.pathname.startsWith('/api/') || url.pathname.startsWith('/ws/')) return;
  if(url.hostname.includes('firebaseio') || url.hostname.includes('googleapis')) return;

  event.respondWith(
    caches.match(event.request).then(cached => {
      if(cached) return cached;
      return fetch(event.request).then(response => {
        if(response.ok && event.request.method === 'GET') {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(c => c.put(event.request, clone));
        }
        return response;
      }).catch(() => {
        if(event.request.destination === 'document')
          return caches.match('/index.html');
      });
    })
  );
});
