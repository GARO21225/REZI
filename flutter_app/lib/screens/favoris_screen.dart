import 'package:flutter/material.dart';
import '../models/residence.dart';
import '../services/api_service.dart';
import '../widgets/residence_card.dart';
import 'residence_detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _api = ApiService();
  late Future<List<Residence>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchFavoris();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: FutureBuilder<List<Residence>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucun favori pour le moment.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => ResidenceCard(
              residence: items[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ResidenceDetailScreen(id: items[i].id)),
              ),
            ),
          );
        },
      ),
    );
  }
}
