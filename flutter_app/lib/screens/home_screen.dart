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

  static const _categories = [
    ('Tous', Icons.apps_rounded),
    ('Studio', Icons.bed_outlined),
    ('Appartement', Icons.apartment_outlined),
    ('Villa', Icons.villa_outlined),
    ('Chambre', Icons.hotel_outlined),
  ];
  String _categorieActive = 'Tous';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchResidences();
  }

  void _reload() {
    setState(() => _future = _api.fetchResidences(
      type: _categorieActive == 'Tous' ? null : _categorieActive,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            slivers: [
              // ── En-tête : salutation + localisation + notifications ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      const ReziAvatar(initials: 'U', size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour 👋', style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: ReziTokens.accent),
                                const SizedBox(width: 2),
                                Text('Grand Abidjan', style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Accroche ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Text('Trouvez votre\nprochaine résidence',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
                ),
              ),
              // ── Barre de recherche + filtre ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Quartier, ville, résidence...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onSubmitted: (_) => _reload(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: ReziTokens.accentGradient,
                          borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
                        ),
                        child: IconButton(
                          onPressed: _reload,
                          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Chips de catégories ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final (label, icon) = _categories[i];
                      final active = label == _categorieActive;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _categorieActive = label);
                          _reload();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            gradient: active ? ReziTokens.accentGradient : null,
                            color: active ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: active ? Colors.white : null),
                              const SizedBox(width: 6),
                              Text(label, style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : null,
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ── Section titre ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recommandé pour vous', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
              // ── Grille de résidences ──
              FutureBuilder<List<Residence>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
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
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(child: Text('Aucune résidence trouvée.',
                            style: Theme.of(context).textTheme.bodyMedium)),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ResidenceCard(
                          residence: items[i],
                          isFavori: _favoris.contains(items[i].id),
                          onToggleFavori: (v) => setState(
                            () => v ? _favoris.add(items[i].id) : _favoris.remove(items[i].id),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ResidenceDetailScreen(id: items[i].id)),
                          ),
                        ),
                        childCount: items.length,
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
