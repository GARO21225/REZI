import 'package:flutter/material.dart';
import '../theme/rezi_theme.dart';
import '../services/api_service.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final loggedIn = await _api.isLoggedIn;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => loggedIn ? const MainShell() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ReziLogoBadge(size: 64),
            const SizedBox(height: 16),
            Text('REZI', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 4),
            Text('Trouvez votre résidence', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
