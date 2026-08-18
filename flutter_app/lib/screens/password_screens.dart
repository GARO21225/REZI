import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';

class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  final _api = ApiService();
  final _email = TextEditingController();
  bool _loading = false;
  bool _envoye = false;
  String? _error;

  Future<void> _envoyer() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _api.motDePasseOublie(_email.text.trim());
      setState(() => _envoye = true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _envoye
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 48, color: ReziTokens.success),
                      const SizedBox(height: 12),
                      Text('Un lien de réinitialisation a été envoyé à ${_email.text}.',
                          textAlign: TextAlign.center),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Réinitialiser le mot de passe', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Votre email'),
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
                            : ReziPrimaryButton(label: 'Envoyer le lien', onPressed: _envoyer),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class ChangerMotDePasseScreen extends StatefulWidget {
  const ChangerMotDePasseScreen({super.key});

  @override
  State<ChangerMotDePasseScreen> createState() => _ChangerMotDePasseScreenState();
}

class _ChangerMotDePasseScreenState extends State<ChangerMotDePasseScreen> {
  final _api = ApiService();
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _succes;

  Future<void> _valider() async {
    if (_nouveau.text.length < 6) {
      setState(() => _error = 'Le nouveau mot de passe doit faire au moins 6 caractères.');
      return;
    }
    setState(() { _loading = true; _error = null; _succes = null; });
    try {
      await _api.changerMotDePasse(_ancien.text, _nouveau.text);
      setState(() => _succes = 'Mot de passe modifié avec succès.');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _ancien, obscureText: true,
                    decoration: const InputDecoration(hintText: 'Ancien mot de passe')),
                const SizedBox(height: 10),
                TextField(controller: _nouveau, obscureText: true,
                    decoration: const InputDecoration(hintText: 'Nouveau mot de passe')),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: ReziTokens.danger, fontSize: 12)),
                ],
                if (_succes != null) ...[
                  const SizedBox(height: 12),
                  Text(_succes!, style: const TextStyle(color: ReziTokens.success, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ReziPrimaryButton(label: 'Valider', onPressed: _valider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
