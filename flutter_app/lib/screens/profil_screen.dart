import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';
import 'password_screens.dart';
import 'proprietaire_screens.dart';
import 'login_screen.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SizedBox(height: 20),
          const Center(child: ReziAvatar(initials: 'U', size: 64)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.villa_outlined),
            title: const Text('Espace propriétaire'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DemandeProprietaireScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_home_outlined),
            title: const Text('Publier une résidence'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreerResidenceScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inbox_outlined),
            title: const Text('Réservations reçues'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReservationsProprietaireScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangerMotDePasseScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: ReziTokens.danger),
            title: const Text('Se déconnecter', style: TextStyle(color: ReziTokens.danger)),
            onTap: () async {
              await api.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
