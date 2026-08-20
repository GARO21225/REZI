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
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(opacity: value, child: child),
            child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Carrousel photo plein écran, avec effet parallax/stretch au scroll ──
                  SliverAppBar(
                    expandedHeight: 340,
                    pinned: false,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    stretchTriggerOffset: 100,
                    onStretchTrigger: () async {},
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Stack(
                      children: [
                        Positioned.fill(
                          child: r.photos.isEmpty
                              ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                              : PageView.builder(
                                  controller: _pageCtrl,
                                  itemCount: r.photos.length,
                                  onPageChanged: (i) => setState(() => _photoIndex = i),
                                  itemBuilder: (_, i) => i == 0
                                      ? Hero(
                                          tag: 'residence-photo-${r.id}',
                                          child: CachedNetworkImage(
                                            imageUrl: r.photos[i], fit: BoxFit.cover, width: double.infinity,
                                          ),
                                        )
                                      : CachedNetworkImage(
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
                        // ── Pastille note + type, façon "4.9 Apartment" de la référence ──
                        Positioned(
                          bottom: 26, left: 16,
                          child: Row(
                            children: [
                              if (r.note != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: ReziTokens.accent),
                                      const SizedBox(width: 3),
                                      Text(r.note!.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ReziTokens.text)),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ReziTokens.disponibleBadgeColor(r.disponible),
                                  borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
                                ),
                                child: Text(
                                  r.disponible ? r.type : 'Indisponible',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                                        const Icon(Icons.location_on_outlined, size: 14, color: ReziTokens.textMuted),
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
                            child: (r.latitude == 0 && r.longitude == 0)
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: ReziTokens.surface2,
                                      borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_off_outlined, color: ReziTokens.textMuted),
                                        const SizedBox(height: 6),
                                        Text('Position non disponible', style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
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
                                          urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                          userAgentPackageName: 'com.orange.rezi',
                                          errorTileCallback: (tile, error, stackTrace) {},
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
                    ReziGhostIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        ReziGhostIconButton(icon: Icons.ios_share_rounded, onTap: () {}),
                        const SizedBox(width: 8),
                        ReziGhostIconButton(
                          icon: _favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: _favori ? ReziTokens.danger : ReziTokens.primary,
                          onTap: () => setState(() => _favori = !_favori),
                          animateScale: _favori,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Pilule de réservation flottante, façon référence détail ──
              Positioned(
                left: 20, right: 20, bottom: 20,
                child: FutureBuilder<Residence>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final r = snap.data!;
                    return Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2A22),
                        borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: r.prix),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) => Text(
                                  '${value.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const Text('par nuit', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 28, color: Colors.white24),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text('Choisir les dates',
                                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ReziCircleActionButton(
                            icon: Icons.arrow_forward_rounded,
                            onPressed: r.disponible ? () => _reserver(context, r) : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          );
        },
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
