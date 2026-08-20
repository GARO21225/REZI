import 'package:flutter/material.dart';
import '../models/residence.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';
import '../widgets/residence_card.dart';
import 'residence_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  late Future<List<Residence>> _future;
  final _searchCtrl = TextEditingController();
  final _favoris = <String>{};
  List<Map<String, dynamic>> _suggestions = [];
  bool _rechercheOuverte = false;
  double? _lat;
  double? _lng;
  String _categorieActive = 'Tous';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchResidences();
  }

  void _reload() => setState(
    () => _future = _api.fetchResidences(lat: _lat, lng: _lng, rayonKm: (_lat != null) ? 15 : null),
  );

  Future<void> _onSearchChanged(String q) async {
    if (q.trim().length < 2) {
      setState(() { _suggestions = []; _rechercheOuverte = false; });
      return;
    }
    final res = await _api.suggestionsAdresse(q);
    if (!mounted) return;
    setState(() { _suggestions = res; _rechercheOuverte = res.isNotEmpty; });
  }

  void _selectionnerSuggestion(Map<String, dynamic> s) {
    _searchCtrl.text = '${s['nom']}${(s['ville'] as String).isNotEmpty ? ', ${s['ville']}' : ''}';
    setState(() {
      _lat = (s['latitude'] as num).toDouble();
      _lng = (s['longitude'] as num).toDouble();
      _suggestions = [];
      _rechercheOuverte = false;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReziTokens.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            slivers: [
              // ── Localisation + notifications ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: ReziTokens.primarySoft, shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded, size: 18, color: ReziTokens.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Localisation actuelle', style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                Text('Grand Abidjan', style: Theme.of(context).textTheme.titleMedium),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ReziTokens.textMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: ReziTokens.surface2, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Recherche + filtre + suggestions géographiques ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Quartier, ville, résidence...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                suffixIcon: (_lat != null)
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() { _lat = null; _lng = null; _suggestions = []; });
                                          _reload();
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: _onSearchChanged,
                              onSubmitted: (_) => _reload(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(gradient: ReziTokens.primaryGradient, shape: BoxShape.circle),
                            child: IconButton(
                              onPressed: _reload,
                              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      if (_rechercheOuverte)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
                            border: Border.all(color: ReziTokens.border),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _suggestions.map((s) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined, size: 18, color: ReziTokens.primary),
                              title: Text(s['nom'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: (s['ville'] as String).isNotEmpty
                                  ? Text(s['ville'] as String, style: const TextStyle(fontSize: 11))
                                  : null,
                              onTap: () => _selectionnerSuggestion(s),
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Bannière promo animée (respiration douce) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _PulsingBanner(),
                ),
              ),
              // ── Onglets catégories avec compteurs, façon référence ──
              FutureBuilder<List<Residence>>(
                future: _future,
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  final counts = <String, int>{};
                  for (final r in items) {
                    counts[r.type] = (counts[r.type] ?? 0) + 1;
                  }
                  final categories = ['Tous', ...counts.keys];
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final active = cat == _categorieActive;
                            final count = cat == 'Tous' ? items.length : counts[cat];
                            return Padding(
                              padding: const EdgeInsets.only(right: 22),
                              child: GestureDetector(
                                onTap: () => setState(() => _categorieActive = cat),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: active ? 15 : 14,
                                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                                    color: active ? ReziTokens.text : ReziTokens.textMuted,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$cat${count != null ? ' $count' : ''}'),
                                      const SizedBox(height: 4),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: 2, width: active ? 22 : 0,
                                        color: ReziTokens.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // ── Grille mosaïque avec entrée en cascade ──
              FutureBuilder<List<Residence>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
                    );
                  }
                  if (snap.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Impossible de charger les résidences.\n${snap.error}',
                            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    );
                  }
                  var items = snap.data ?? [];
                  if (_categorieActive != 'Tous') {
                    items = items.where((r) => r.type == _categorieActive).toList();
                  }
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(child: Text('Aucune résidence trouvée.', style: Theme.of(context).textTheme.bodyMedium)),
                      ),
                    );
                  }
                  // Colonnes gauche/droite en alternance pour l'effet mosaïque
                  final left = <Residence>[];
                  final right = <Residence>[];
                  for (var i = 0; i < items.length; i++) {
                    (i.isEven ? left : right).add(items[i]);
                  }
                  Widget buildColumn(List<Residence> col, int offset) {
                    return Expanded(
                      child: Column(
                        children: List.generate(col.length, (j) {
                          final globalIndex = j * 2 + offset;
                          final ratio = j.isEven ? 0.8 : 1.05;
                          final residence = col[j];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: StaggeredEntrance(
                              index: globalIndex,
                              child: ResidenceCard(
                                residence: residence,
                                photoAspectRatio: ratio,
                                isFavori: _favoris.contains(residence.id),
                                onToggleFavori: (v) => setState(
                                  () => v ? _favoris.add(residence.id) : _favoris.remove(residence.id),
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ResidenceDetailScreen(id: residence.id)),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildColumn(left, 0),
                          const SizedBox(width: 14),
                          buildColumn(right, 1),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bannière promo avec une lueur qui respire doucement — micro-animation
/// continue pour donner un côté vivant à l'accueil.
class _PulsingBanner extends StatefulWidget {
  @override
  State<_PulsingBanner> createState() => _PulsingBannerState();
}

class _PulsingBannerState extends State<_PulsingBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: ReziTokens.primaryGradient,
          borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: ReziTokens.primary.withValues(alpha: 0.25 + _ctrl.value * 0.2),
              blurRadius: 24 + _ctrl.value * 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Réservez tôt,\néconomisez plus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Offres limitées ce mois-ci',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
            ),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
