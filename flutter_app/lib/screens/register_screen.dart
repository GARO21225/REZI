import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _api = ApiService();
  final _email = TextEditingController();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  final _password = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _otpStep = false;
  String? _error;

  Future<void> _demanderCode() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _error = 'Mot de passe trop court (min 6 caractères).');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _api.demanderOtpInscription(
        email: _email.text.trim(),
        motDePasse: _password.text,
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        telephone: _tel.text.trim(),
      );
      setState(() => _otpStep = true);
    } catch (e) {
      // Fallback : si l'API OTP est indisponible, inscription directe (comme le site web)
      try {
        await _api.registerDirect(
          email: _email.text.trim(),
          motDePasse: _password.text,
          nom: _nom.text.trim(),
          prenom: _prenom.text.trim(),
          telephone: _tel.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
        return;
      } catch (e2) {
        setState(() => _error = '$e2');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifierCode() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = 'Entrez les 6 chiffres du code.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _api.verifierOtpInscription(_email.text.trim(), code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildOtpField(int i) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _otpControllers[i],
        focusNode: _otpFocus[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(counterText: ''),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
          if (v.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
          if (i == 5 && v.isNotEmpty) _verifierCode();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_otpStep ? 'Vérification' : 'Inscription')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _otpStep ? _buildOtpStep() : _buildFormStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      children: [
        const ReziLogoBadge(size: 56),
        const SizedBox(height: 16),
        Text('Créer un compte', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 20),
        TextField(controller: _prenom, decoration: const InputDecoration(hintText: 'Prénom')),
        const SizedBox(height: 10),
        TextField(controller: _nom, decoration: const InputDecoration(hintText: 'Nom')),
        const SizedBox(height: 10),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email')),
        const SizedBox(height: 10),
        TextField(controller: _tel, keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Téléphone')),
        const SizedBox(height: 10),
        TextField(controller: _password, obscureText: true,
            decoration: const InputDecoration(hintText: 'Mot de passe (min. 6 caractères)')),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: ReziTokens.danger, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ReziPrimaryButton(label: 'Créer mon compte', onPressed: _demanderCode),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Icon(Icons.mail_outline_rounded, size: 40, color: ReziTokens.accent),
        const SizedBox(height: 8),
        Text('Vérifiez votre email', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Code à 6 chiffres envoyé à ${_email.text}',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildOtpField(i),
          )),
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
              : ReziPrimaryButton(label: 'Valider mon compte', onPressed: _verifierCode),
        ),
        TextButton(onPressed: _demanderCode, child: const Text('Renvoyer le code')),
      ],
    );
  }
}
