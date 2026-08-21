import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/social_auth_service.dart';
import '../theme/rezi_theme.dart';
import 'main_shell.dart';
import 'register_screen.dart';
import 'password_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = ApiService();
  final _social = SocialAuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      setState(() => _error = 'Connexion échouée. Vérifiez vos identifiants.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connexionSociale(Future<String> Function() action, String nom) async {
    setState(() { _loading = true; _error = null; });
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      setState(() => _error = 'Connexion $nom échouée. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ReziLogoBadge(size: 56),
                const SizedBox(height: 16),
                Text('Connexion', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ReziTokens.danger, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ReziPrimaryButton(label: 'Se connecter', fullWidth: true, onPressed: _submit),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: ReziTokens.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('ou', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Expanded(child: Divider(color: ReziTokens.border)),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Connexion sociale ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _connexionSociale(_social.signInWithGoogle, 'Google'),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: ReziTokens.text),
                    label: const Text('Continuer avec Google'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _connexionSociale(_social.signInWithApple, 'Apple'),
                    icon: const Icon(Icons.apple_rounded, size: 22, color: ReziTokens.text),
                    label: const Text('Continuer avec Apple'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Créer un compte'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MotDePasseOublieScreen()),
                  ),
                  child: const Text('Mot de passe oublié ?'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                  ),
                  child: const Text('Continuer sans se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
