import 'package:flutter/material.dart';
import '../theme/rezi_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReziTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ReziLogoBadge(size: 30),
                  const SizedBox(width: 8),
                  Text('REZI', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 28),
              // ── Visuel principal arrondi, façon référence ──
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(color: ReziTokens.surface2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Trouvez votre\nrésidence idéale', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 10),
              Text(
                'Explorez, comparez et réservez des résidences vérifiées '
                'partout dans le Grand Abidjan.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ReziTokens.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ReziPrimaryButton(
                  label: 'Commencer',
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
