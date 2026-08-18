import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/residence.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';

class ResidenceDetailScreen extends StatefulWidget {
  final String id;
  const ResidenceDetailScreen({super.key, required this.id});

  @override
  State<ResidenceDetailScreen> createState() => _ResidenceDetailScreenState();
}

class _ResidenceDetailScreenState extends State<ResidenceDetailScreen> {
  final _api = ApiService();
  late Future<Residence> _future;
  bool _favori = false;
  int _photoIndex = 0;
  final _pageCtrl = PageController();
  bool _descriptionOuverte = false;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchResidence(widget.id);
  }

  Future<void> _reserver(BuildContext context, Residence r) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (range == null || !context.mounted) return;
    try {
      final reservation = await _api.creerReservation(
        residenceId: r.id, debut: range.start, fin: range.end,
      );
      if (!context.mounted) return;
      final paiement = await _api.initierPaiement(reservation.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation créée. Paiement : ${paiement['statut'] ?? 'en attente'}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: FutureBuilder<Residence>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          final r = snap.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Carrousel photo plein écran avec indicateurs ──
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 340,
                          child: r.photos.isEmpty
                              ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                              : PageView.builder(
                                  controller: _pageCtrl,
                                  itemCount: r.photos.length,
                                  onPageChanged: (i) => setState(() => _photoIndex = i),
                                  itemBuilder: (_, i) => CachedNetworkImage(
                                    imageUrl: r.photos[i], fit: BoxFit.cover, width: double.infinity,
                                  ),
                                ),
                        ),
                        if (r.photos.length > 1)
                          Positioned(
                            bottom: 14, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(r.photos.length, (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _photoIndex ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _photoIndex ? Colors.white : Colors.white38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              )),
                            ),
                          ),
                        if (!r.disponible)
                          Positioned(
                            top: 100, left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: ReziTokens.danger,
                                borderRadius: BorderRadius.circular(ReziTokens.radiusSm),
                              ),
                              child: const Text('Indisponible',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ── Contenu ──
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      transform: Matrix4.translationValues(0, -20, 0),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.titre, style: Theme.of(context).textTheme.displayMedium),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: ReziTokens.darkTextMuted),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(r.adresse ?? r.type,
                                            style: Theme.of(context).textTheme.bodyMedium)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (r.note != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: ReziTokens.accent),
                                      const SizedBox(width: 4),
                                      Text(r.note!.toStringAsFixed(1),
                                          style: Theme.of(context).textTheme.titleMedium),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // ── Équipements clés (icônes rapides, façon référence 3) ──
                          Row(
                            children: [
                              _InfoPill(icon: Icons.home_work_outlined, label: r.type),
                              const SizedBox(width: 10),
                              _InfoPill(
                                icon: r.disponible ? Icons.check_circle_outline : Icons.cancel_outlined,
                                label: r.disponible ? 'Disponible' : 'Indisponible',
                                color: r.disponible ? ReziTokens.success : ReziTokens.danger,
                              ),
                            ],
                          ),
                          if (r.description != null) ...[
                            const SizedBox(height: 24),
                            Text('Description', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              r.description!,
                              maxLines: _descriptionOuverte ? null : 3,
                              overflow: _descriptionOuverte ? null : TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _descriptionOuverte = !_descriptionOuverte),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(_descriptionOuverte ? 'Voir moins' : 'Voir plus',
                                    style: const TextStyle(color: ReziTokens.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text('Localisation', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 180,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(r.latitude, r.longitude),
                                  initialZoom: 14,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                    subdomains: const ['a', 'b', 'c'],
                                  ),
                                  MarkerLayer(markers: [
                                    Marker(
                                      point: LatLng(r.latitude, r.longitude),
                                      width: 34, height: 34,
                                      child: const ReziLogoBadge(size: 30),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Avis', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<List<Avis>>(
                            future: _api.fetchAvis(r.id),
                            builder: (context, avisSnap) {
                              final avis = avisSnap.data ?? [];
                              if (avisSnap.connectionState == ConnectionState.waiting) {
                                return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));
                              }
                              if (avis.isEmpty) {
                                return Text('Aucun avis pour l\'instant.', style: Theme.of(context).textTheme.bodyMedium);
                              }
                              return Column(
                                children: avis.map((a) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        ReziAvatar(initials: a.auteur.isNotEmpty ? a.auteur[0] : '?', size: 26),
                                        const SizedBox(width: 8),
                                        Text(a.auteur, style: Theme.of(context).textTheme.titleMedium),
                                        const Spacer(),
                                        Row(children: List.generate(5, (i) => Icon(
                                          i < a.note ? Icons.star_rounded : Icons.star_border_rounded,
                                          size: 13, color: ReziTokens.accent,
                                        ))),
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(a.commentaire, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                )).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // ── Icônes flottantes (retour, partage, favori) sur l'image ──
              Positioned(
                top: 50, left: 16, right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        _CircleIconButton(icon: Icons.share_outlined, onTap: () {}),
                        const SizedBox(width: 8),
                        _CircleIconButton(
                          icon: _favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: _favori ? ReziTokens.accent2 : Colors.white,
                          onTap: () => setState(() => _favori = !_favori),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Barre de réservation sticky en bas ──
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: FutureBuilder<Residence>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final r = snap.data!;
                    return Container(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -4))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${r.prix.toStringAsFixed(0)} FCFA',
                                    style: Theme.of(context).textTheme.displayMedium
                                        ?.copyWith(color: ReziTokens.accent, fontSize: 20)),
                                Text('par nuit', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          ReziPrimaryButton(
                            label: 'Réserver',
                            icon: Icons.event_available_rounded,
                            onPressed: r.disponible ? () => _reserver(context, r) : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color ?? ReziTokens.accent),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
