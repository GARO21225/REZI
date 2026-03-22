# 📱 Guide de publication mobile — PCR ou Loger

## Prérequis

- Node.js ≥ 18
- Android Studio (pour Android)
- Xcode 15+ sur macOS (pour iOS)
- Compte Google Play Console
- Compte Apple Developer (99$/an)

---

## 🚀 Étape 1 — Installation Capacitor

```bash
cd pcr-ou-loger
npm install

# Initialiser les plateformes
npm run add:android
npm run add:ios    # macOS uniquement
```

---

## 🔄 Étape 2 — Synchroniser le frontend

À chaque modification du frontend :
```bash
npm run sync
```

---

## 🤖 Android — Google Play Store

### Build de développement
```bash
npm run android
# → Android Studio s'ouvre
# → Run 'app' sur émulateur ou appareil
```

### Build de production (APK signé)

1. **Générer le keystore** (une seule fois) :
```bash
keytool -genkey -v \
  -keystore pcr-ouloger-release.keystore \
  -alias pcr-ouloger \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=PCR ou Loger, OU=Dev, O=PCR, L=Abidjan, S=CI, C=CI"
```

2. **Configurer `android/app/build.gradle`** :
```groovy
android {
    signingConfigs {
        release {
            storeFile file('../../pcr-ouloger-release.keystore')
            storePassword 'VOTRE_MOT_DE_PASSE'
            keyAlias 'pcr-ouloger'
            keyPassword 'VOTRE_MOT_DE_PASSE'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

3. **Générer l'AAB** (format requis par le Play Store) :
```bash
cd android
./gradlew bundleRelease
# → android/app/build/outputs/bundle/release/app-release.aab
```

4. **Publier sur Google Play Console** :
   - Créez une application sur https://play.google.com/console
   - Production → Créer une version → Importer l'AAB
   - Remplissez la fiche : description FR, captures d'écran, icônes
   - Soumettez pour révision (1-3 jours)

### Permissions Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## 🍎 iOS — Apple App Store

### Build de développement
```bash
npm run ios
# → Xcode s'ouvre
# → Sélectionnez un simulateur ou appareil → Run
```

### Permissions iOS (`ios/App/App/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PCR ou Loger utilise votre position pour trouver les logements proches.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Votre position permet de calculer les distances vers les résidences.</string>

<key>NSCameraUsageDescription</key>
<string>Pour photographier vos justificatifs et les photos de résidence.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Pour sélectionner des photos depuis votre galerie.</string>
```

### Build de production
1. Xcode → Product → Archive
2. Distribute App → App Store Connect
3. Connectez-vous sur https://appstoreconnect.apple.com
4. Remplissez la fiche : métadonnées FR, captures d'écran iPhone/iPad
5. Soumettez pour révision Apple (1-5 jours)

---

## 🌐 PWA — Alternative rapide (sans App Store)

Ajoutez dans `<head>` de `index.html` :
```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0b0f1a">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="PCR ou Loger">
<link rel="apple-touch-icon" href="/icons/icon-192.png">
```

Enregistrer le Service Worker dans `index.html` avant `</body>` :
```html
<script>
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js')
    .then(reg => console.log('SW enregistré:', reg.scope))
    .catch(err => console.error('SW erreur:', err));
}
</script>
```

L'utilisateur peut alors ajouter l'app sur son écran d'accueil depuis Safari (iOS) ou Chrome (Android) sans passer par les stores.

---

## 🔑 Variables d'environnement Mobile Money

Créez `.env` dans `/backend` :
```env
# Application
ENV=production
SECRET_KEY=changez-cette-cle-en-production-longue-et-aleatoire
CALLBACK_BASE_URL=https://votre-domaine.com

# Orange Money CI
ORANGE_MONEY_TOKEN=votre_token_orange
ORANGE_MERCHANT_KEY=votre_cle_marchand

# MTN MoMo
MTN_MOMO_SUBSCRIPTION_KEY=votre_cle_abonnement
MTN_MOMO_USER_ID=votre_user_id
MTN_MOMO_API_KEY=votre_api_key
MTN_ENV=production

# Wave
WAVE_API_KEY=votre_cle_wave

# Base de données
DATABASE_URL=postgresql://user:password@host:5432/pcr_ou_loger
```

---

## 📞 Contacts opérateurs Mobile Money CI

| Opérateur | Portail développeur | Contact |
|-----------|--------------------|---------| 
| Orange Money | https://developer.orange.com | api@orange.ci |
| MTN MoMo | https://momodeveloper.mtn.com | momo.api@mtn.com |
| Wave | https://docs.wave.com | partnerships@wave.com |
| Moov Money | Contact commercial | moov.ci |
