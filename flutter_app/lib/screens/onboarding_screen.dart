import 'package:flutter/material.dart';
import '../theme/rezi_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Visuel plein écran (photo de résidence) avec dégradé sombre en bas
          // pour la lisibilité du texte, comme les références 1 et 4.
          Image.network(
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1200',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: ReziTokens.darkSurface2),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  ReziTokens.darkBg.withValues(alpha: 0.4),
                  ReziTokens.darkBg.withValues(alpha: 0.96),
                  ReziTokens.darkBg,
                ],
                stops: const [0.0, 0.45, 0.8, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ReziLogoBadge(size: 36),
                      const SizedBox(width: 10),
                      Text('REZI', style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trouvez votre\nrésidence idéale',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white, fontSize: 34, height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Studios, appartements et villas dans tout le Grand Abidjan. '
                        'Réservez en toute confiance.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70, height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ReziPrimaryButton(
                          label: 'Commencer',
                          icon: Icons.arrow_forward_rounded,
                          fullWidth: true,
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
