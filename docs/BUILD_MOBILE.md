# 📱 REZI — Build Android & iOS (Capacitor 6)

## Prérequis

| Outil | Version | Installation |
|-------|---------|-------------|
| Node.js | 18+ | https://nodejs.org |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Xcode | 15+ (Mac seulement) | App Store Mac |
| Java JDK | 17 | `brew install openjdk@17` |

---

## Installation initiale

```bash
cd ~/app   # dossier racine REZI

# Installer les dépendances
npm install

# Initialiser Capacitor (si pas encore fait)
npx cap init
```

---

## 🤖 Build Android (APK / AAB Play Store)

```bash
# 1. Copier le frontend dans le dossier www
mkdir -p www
cp frontend/index.html www/
cp frontend/sw.js www/
cp frontend/manifest.json www/
cp frontend/paiement.html www/

# 2. Ajouter la plateforme Android
npx cap add android

# 3. Synchroniser le code
npx cap sync android

# 4. Ouvrir Android Studio
npx cap open android
```

Dans Android Studio :
- **Build → Generate Signed Bundle / APK**
- Choisir **Android App Bundle** (.aab) pour le Play Store
- Ou **APK** pour distribution directe

### Signature de l'APK

```bash
# Créer un keystore (une seule fois)
keytool -genkey -v -keystore rezi.keystore \
  -alias rezi -keyalg RSA -keysize 2048 -validity 10000

# Dans android/app/build.gradle, ajouter :
android {
  signingConfigs {
    release {
      storeFile file('../../rezi.keystore')
      storePassword 'VOTRE_MOT_DE_PASSE'
      keyAlias 'rezi'
      keyPassword 'VOTRE_MOT_DE_PASSE'
    }
  }
  buildTypes {
    release {
      signingConfig signingConfigs.release
      minifyEnabled true
    }
  }
}
```

### Configuration de l'URL de production

Dans `capacitor.config.ts`, s'assurer que le serveur pointe vers prod :
```typescript
// Pour production (commenter pour le dev)
// server: { url: 'http://localhost:8000', cleartext: true }
```

---

## 🍎 Build iOS (IPA App Store) — Mac requis

```bash
# 1. Ajouter la plateforme iOS
npx cap add ios

# 2. Synchroniser
npx cap sync ios

# 3. Ouvrir Xcode
npx cap open ios
```

Dans Xcode :
- Sélectionner votre **Team** (compte Apple Developer — 99$/an)
- **Bundle Identifier** : `ci.rezi.app`
- **Product → Archive** pour créer l'IPA
- **Window → Organizer → Distribute App** pour envoyer à l'App Store

### Permissions iOS (Info.plist)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>REZI utilise votre position pour calculer l'itinéraire vers les résidences.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>REZI utilise votre position pour la navigation GPS.</string>
```

---

## 🔔 Notifications push sur mobile

### Android
Dans `android/app/src/main/AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
```

Télécharger `google-services.json` depuis Firebase Console et le placer dans `android/app/`.

### iOS
Télécharger `GoogleService-Info.plist` depuis Firebase Console et l'ajouter dans Xcode (drag & drop dans le dossier `App`).

---

## Mise à jour de l'app

```bash
# Modifier le frontend
# Puis :
npx cap sync
npx cap open android  # ou ios
# Rebuilder dans l'IDE
```

---

## Publication

### Play Store
1. Créer un compte Google Play Developer (25$ une fois)
2. Créer une nouvelle application dans la console Play
3. Uploader l'AAB dans **Production → Releases**
4. Remplir les infos, screenshots, politique de confidentialité
5. Soumettre pour review (1-3 jours)

### App Store
1. Créer un compte Apple Developer (99$/an)
2. Créer l'app dans App Store Connect
3. Uploader via Xcode Organizer
4. Remplir les métadonnées et screenshots
5. Soumettre pour review (1-7 jours)

