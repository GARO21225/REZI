# 🏠 PCR ou Loger

Application de réservation géolocalisée multi-plateforme — style Booking.com adapté à la Côte d'Ivoire.

---

## 🚀 Lancement rapide avec Docker

```bash
git clone <repo>
cd pcr-ou-loger
docker-compose up --build
```

Accès :
- **Frontend** : http://localhost:3000
- **API Backend** : http://localhost:8000
- **Documentation API** : http://localhost:8000/docs

---

## 🗂️ Architecture

```
pcr-ou-loger/
├── backend/
│   ├── main.py               # FastAPI app
│   ├── database.py           # SQLAlchemy + PostGIS
│   ├── models/
│   │   ├── user.py           # Modèle Utilisateur (usager/propriétaire)
│   │   ├── residence.py      # Modèle Résidence + géométrie PostGIS
│   │   └── reservation.py    # Modèle Réservation
│   ├── routers/
│   │   ├── auth.py           # Inscription, connexion JWT
│   │   ├── residences.py     # CRUD résidences + recherche géospatiale
│   │   ├── reservations.py   # Réservations + avis
│   │   └── users.py          # Gestion utilisateurs
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   └── index.html            # SPA complète (carte Leaflet + UI)
├── docker-compose.yml
└── nginx.conf
```

---

## ⚙️ Stack technique

| Couche | Technologie |
|--------|------------|
| Backend | FastAPI (Python 3.11) |
| Base de données | PostgreSQL 16 + PostGIS 3.4 |
| Géospatial | GeoAlchemy2, GeoPy, OSRM (itinéraires) |
| Auth | JWT (PyJWT + bcrypt) |
| Cartographie | Leaflet.js + CartoDB Dark tiles |
| Frontend | HTML/CSS/JS (SPA) + Leaflet |
| Déploiement | Docker + Nginx |

---

## 📱 Publication mobile (PWA + App Store)

### Option 1 : PWA (recommandé, rapide)
Ajoutez dans `frontend/index.html` :
```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0b0f1a">
```
Créez `frontend/manifest.json` :
```json
{
  "name": "PCR ou Loger",
  "short_name": "PCR Loger",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0b0f1a",
  "theme_color": "#f5a623",
  "icons": [{"src": "icon-512.png", "sizes": "512x512", "type": "image/png"}]
}
```

### Option 2 : Wrapper natif (Capacitor)
```bash
npm install @capacitor/core @capacitor/cli
npx cap init "PCR ou Loger" "com.pcr.loger"
npx cap add android
npx cap add ios
npx cap sync
npx cap open android   # → Android Studio → Google Play
npx cap open ios       # → Xcode → App Store
```

---

## 🔑 Variables d'environnement

```env
DATABASE_URL=postgresql://postgres:password@db:5432/pcr_ou_loger
SECRET_KEY=your-very-long-secret-key
```

---

## 📋 Fonctionnalités implémentées

- ✅ Carte interactive Leaflet.js (thème sombre)
- ✅ Marqueurs de prix dynamiques sur la carte
- ✅ Géolocalisation utilisateur + calcul distance
- ✅ Itinéraires via OSRM (Open Source Routing Machine)
- ✅ Filtres : type, prix, disponibilité, recherche textuelle
- ✅ Comptes Usager / Propriétaire avec JWT
- ✅ Inscription avec pièces justificatives obligatoires
- ✅ Ajout résidence avec photo façade obligatoire + photos multiples
- ✅ Réservation avec calcul prix automatique
- ✅ Détection conflits de réservations
- ✅ Avis / notations post-séjour
- ✅ Recherche géospatiale avec PostGIS (ST_DWithin)
- ✅ Mode démo (fonctionne sans backend)
- ✅ Responsive desktop/tablette/mobile

---

## 🛡️ Sécurité

- Mots de passe hashés avec bcrypt
- Tokens JWT avec expiration 24h
- Documents stockés dans dossier sécurisé `/uploads`
- CORS configuré (à restreindre en production)
- Stockage chiffré recommandé : utiliser S3 + SSE ou MinIO chiffré
