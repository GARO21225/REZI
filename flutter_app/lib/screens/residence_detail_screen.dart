import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/residence.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _api.fetchResidence(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: r.photos.isNotEmpty
                      ? Image.network(r.photos.first, fit: BoxFit.cover)
                      : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.titre, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text(r.adresse ?? r.type, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Text('${r.prix.toStringAsFixed(0)} FCFA / nuit',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ReziTokens.accent)),
                      const SizedBox(height: 16),
                      if (r.description != null) ...[
                        Text('Description', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(r.description!, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                      ],
                      Text('Localisation', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(r.latitude, r.longitude),
                              initialZoom: 14,
                              interactionOptions:
                                  const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(r.latitude, r.longitude),
                                  width: 34,
                                  height: 34,
                                  child: const ReziLogoBadge(size: 30),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ReziPrimaryButton(
                        label: 'Réserver',
                        icon: Icons.event_available_rounded,
                        onPressed: () {
                          // TODO: brancher sur POST /reservations (voir backend/routers/reservations.py)
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
