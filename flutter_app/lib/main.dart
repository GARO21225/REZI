import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/rezi_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Tant que firebase_options.dart contient des valeurs placeholder,
    // l'initialisation échoue silencieusement — l'app continue de
    // fonctionner normalement, seule la connexion Google/Apple sera indisponible.
    debugPrint('Firebase non initialisé (config placeholder) : $e');
  }
  runApp(const ReziApp());
}

class ReziApp extends StatelessWidget {
  const ReziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REZI',
      debugShowCheckedModeBanner: false,
      theme: ReziTheme.light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
