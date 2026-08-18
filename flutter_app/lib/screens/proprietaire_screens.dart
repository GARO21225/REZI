import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';

/// Écran d'entrée : demander le statut propriétaire si pas encore accordé.
class DemandeProprietaireScreen extends StatefulWidget {
  const DemandeProprietaireScreen({super.key});

  @override
  State<DemandeProprietaireScreen> createState() => _DemandeProprietaireScreenState();
}

class _DemandeProprietaireScreenState extends State<DemandeProprietaireScreen> {
  final _api = ApiService();
  bool _loading = false;
  bool _envoyee = false;
  String? _error;

  Future<void> _demander() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _api.demandeProprietaire();
      setState(() => _envoyee = true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devenir propriétaire')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _envoyee
              ? const Text('Votre demande a été envoyée. Vous serez notifié une fois approuvée.',
                  textAlign: TextAlign.center)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.villa_outlined, size: 48, color: ReziTokens.accent),
                    const SizedBox(height: 12),
                    const Text('Publiez vos résidences sur REZI et gérez vos réservations.',
                        textAlign: TextAlign.center),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: ReziTokens.danger, fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    _loading
                        ? const CircularProgressIndicator()
                        : ReziPrimaryButton(label: 'Demander le statut propriétaire', onPressed: _demander),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Formulaire de création de résidence avec upload de photos multiples.
class CreerResidenceScreen extends StatefulWidget {
  const CreerResidenceScreen({super.key});

  @override
  State<CreerResidenceScreen> createState() => _CreerResidenceScreenState();
}

class _CreerResidenceScreenState extends State<CreerResidenceScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  final _titre = TextEditingController();
  final _type = TextEditingController(text: 'studio');
  final _prix = TextEditingController();
  final _adresse = TextEditingController();
  final _description = TextEditingController();
  List<XFile> _photos = [];
  List<Uint8List> _photoBytes = [];
  bool _loading = false;
  String? _error;

  Future<void> _choisirPhotos() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    final bytes = await Future.wait(images.map((f) => f.readAsBytes()));
    setState(() { _photos = images; _photoBytes = bytes; });
  }

  Future<void> _publier() async {
    if (_titre.text.trim().isEmpty || _prix.text.trim().isEmpty) {
      setState(() => _error = 'Titre et prix sont obligatoires.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // NB : latitude/longitude idéalement issues de suggestionsAdresse() sur l'adresse saisie.
      await _api.creerResidence({
        'titre': _titre.text.trim(),
        'type': _type.text.trim(),
        'prix': _prix.text.trim(),
        'adresse': _adresse.text.trim(),
        'description': _description.text.trim(),
      }, List.generate(_photos.length, (i) => (_photos[i].name, _photoBytes[i])));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une résidence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _choisirPhotos,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
              ),
              child: _photos.isEmpty
                  ? const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 36))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoBytes.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ReziTokens.radiusSm),
                          child: Image.memory(_photoBytes[i], width: 110, fit: BoxFit.cover),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${_photos.length} photo(s) sélectionnée(s)', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(controller: _titre, decoration: const InputDecoration(hintText: 'Titre de l\'annonce')),
          const SizedBox(height: 10),
          TextField(controller: _type, decoration: const InputDecoration(hintText: 'Type (studio, villa...)')),
          const SizedBox(height: 10),
          TextField(controller: _prix, keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Prix / nuit (FCFA)')),
          const SizedBox(height: 10),
          TextField(controller: _adresse, decoration: const InputDecoration(hintText: 'Adresse')),
          const SizedBox(height: 10),
          TextField(controller: _description, maxLines: 4,
              decoration: const InputDecoration(hintText: 'Description')),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: ReziTokens.danger, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ReziPrimaryButton(label: 'Publier', icon: Icons.publish_rounded, onPressed: _publier),
        ],
      ),
    );
  }
}

/// Réservations reçues côté propriétaire, avec actions accepter/refuser.
class ReservationsProprietaireScreen extends StatefulWidget {
  const ReservationsProprietaireScreen({super.key});

  @override
  State<ReservationsProprietaireScreen> createState() => _ReservationsProprietaireScreenState();
}

class _ReservationsProprietaireScreenState extends State<ReservationsProprietaireScreen> {
  final _api = ApiService();
  late Future<List<Reservation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.reservationsProprietaire();
  }

  Future<void> _maj(String id, String statut) async {
    await _api.majStatutReservation(id, statut);
    setState(() => _future = _api.reservationsProprietaire());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réservations reçues')),
      body: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Aucune demande pour le moment.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.residenceTitre, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${r.montant.toStringAsFixed(0)} FCFA — ${r.statut}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      if (r.statut == 'en_attente') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(onPressed: () => _maj(r.id, 'refusee'), child: const Text('Refuser')),
                            const SizedBox(width: 8),
                            ReziPrimaryButton(label: 'Accepter', onPressed: () => _maj(r.id, 'confirmee')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

