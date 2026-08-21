import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';

/// Gère la connexion via Google/Apple : authentifie l'utilisateur auprès de
/// Firebase, récupère le jeton d'ID Firebase, puis l'échange contre notre
/// propre JWT auprès du backend REZI (endpoint /auth/social-login).
class SocialAuthService {
  final ApiService _api = ApiService();

  Future<String> signInWithGoogle() async {
    fb.UserCredential cred;
    if (kIsWeb) {
      final provider = fb.GoogleAuthProvider();
      cred = await fb.FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('Connexion annulée');
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await fb.FirebaseAuth.instance.signInWithCredential(credential);
    }
    final idToken = await cred.user!.getIdToken();
    return _api.socialLogin(idToken!);
  }

  Future<String> signInWithApple() async {
    if (kIsWeb) {
      final provider = fb.AppleAuthProvider();
      final cred = await fb.FirebaseAuth.instance.signInWithPopup(provider);
      final idToken = await cred.user!.getIdToken();
      return _api.socialLogin(idToken!);
    }
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauthCredential = fb.OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final cred = await fb.FirebaseAuth.instance.signInWithCredential(oauthCredential);
    final idToken = await cred.user!.getIdToken();
    return _api.socialLogin(idToken!);
  }
}
