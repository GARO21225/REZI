# 🔔 REZI — Configuration Firebase Push Notifications

## Étape 1 — Créer le projet Firebase

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. **Créer un projet** → nommez-le `rezi-ci`
3. Activer **Google Analytics** (optionnel)

## Étape 2 — Activer Cloud Messaging

1. Dans votre projet Firebase → **Paramètres du projet** (⚙️)
2. Onglet **Cloud Messaging**
3. Notez le **Server key** (pour le backend)
4. Onglet **Général** → section "Vos applications" → **Ajouter une application web** (`</>`)
5. Copiez la config `firebaseConfig`

## Étape 3 — Configurer le frontend

Remplacer dans `frontend/index.html` (chercher `VOTRE_API_KEY`) :

```javascript
const FIREBASE_CONFIG = {
  apiKey:            "AIzaSy...",
  authDomain:        "rezi-ci.firebaseapp.com",
  projectId:         "rezi-ci",
  storageBucket:     "rezi-ci.appspot.com",
  messagingSenderId: "123456789",
  appId:             "1:123456789:web:abc123"
};
```

Remplacer aussi dans `frontend/sw.js` :

```javascript
const FIREBASE_CONFIG = { /* même config */ };
```

## Étape 4 — Obtenir la clé VAPID

1. Firebase Console → **Paramètres du projet** → **Cloud Messaging**
2. Section **Certificats push web** → **Générer une paire de clés**
3. Copier la **Clé publique** et remplacer `VOTRE_VAPID_KEY_ICI` dans `index.html`

## Étape 5 — Configurer le backend

1. Firebase Console → **Paramètres du projet** → **Comptes de service**
2. Cliquer **Générer une nouvelle clé privée** → télécharger `serviceAccountKey.json`
3. Placer le fichier dans `backend/serviceAccountKey.json`
4. Ajouter dans `backend/.env` :

```env
FIREBASE_CREDENTIALS_PATH=serviceAccountKey.json
```

5. Ajouter dans le `.gitignore` :
```
backend/serviceAccountKey.json
```

## Étape 6 — Tester

```bash
# Installer firebase-admin
pip install firebase-admin==6.5.0

# Lancer le backend
docker-compose up -d

# Tester via l'API (connecté en tant qu'utilisateur)
curl -X POST http://localhost:8000/api/notifications/test \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type_notif": "nouveau_message", "donnees": {"expediteur": "Koné Mamadou"}}'
```

## Types de notifications disponibles

| Type | Déclencheur |
|------|-------------|
| `reservation_confirmee` | Propriétaire confirme une réservation |
| `paiement_recu` | Paiement Mobile Money reçu |
| `nouveau_message` | Nouveau message dans la messagerie |
| `nouvel_avis` | Client laisse un avis |
| `reservation_annulee` | Réservation annulée |
| `residence_publiee` | Résidence approuvée par l'admin |
| `promo` | Notification marketing (admin) |

## Broadcast (admin)

```bash
curl -X POST http://localhost:8000/api/notifications/broadcast \
  -H "Authorization: Bearer TOKEN_ADMIN" \
  -d '{"type_notif": "promo", "donnees": {"message": "🎉 -20% ce week-end !"}}'
```
