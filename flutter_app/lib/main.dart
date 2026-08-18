import 'package:flutter/material.dart';
import 'theme/rezi_theme.dart';
import 'screens/splash_screen.dart';

void main() {
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
