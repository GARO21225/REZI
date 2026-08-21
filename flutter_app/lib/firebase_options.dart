// ═══════════════════════════════════════════════════════════════
// Configuration Firebase — VALEURS PLACEHOLDER
//
// L'authentification Google/Apple ne fonctionnera PAS tant que ces
// valeurs ne sont pas remplacées par celles de ton vrai projet Firebase.
// Le build compile normalement avec ces valeurs (aucune erreur), mais
// toute tentative de connexion échouera silencieusement côté Firebase
// jusqu'à la vraie configuration.
//
// Comment obtenir les vraies valeurs :
// 1. https://console.firebase.google.com → ouvre le projet existant de
//    REZI (celui déjà utilisé pour les notifications push), ou crées-en
//    un si aucun n'existe encore.
// 2. Paramètres du projet → Général → ajoute une "app Web" si pas déjà fait.
// 3. Copie les valeurs affichées (apiKey, appId, messagingSenderId, projectId,
//    authDomain, storageBucket) dans les champs ci-dessous.
// 4. Dans Firebase Console → Authentication → Sign-in method → active
//    "Google" (et "Apple" si besoin, nécessite un compte Apple Developer).
// ═══════════════════════════════════════════════════════════════

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REMPLACER_PAR_LA_VRAIE_CLE_API',
    appId: 'REMPLACER_PAR_LE_VRAI_APP_ID',
    messagingSenderId: 'REMPLACER_PAR_LE_VRAI_SENDER_ID',
    projectId: 'REMPLACER_PAR_LE_VRAI_PROJECT_ID',
    authDomain: 'REMPLACER.firebaseapp.com',
    storageBucket: 'REMPLACER.appspot.com',
  );
}
