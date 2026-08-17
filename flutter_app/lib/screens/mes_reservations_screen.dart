import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  State<MesReservationsScreen> createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  final _api = ApiService();
  late Future<List<Reservation>> _future;
  final _df = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _future = _api.mesReservations();
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'confirmee':
        return ReziTokens.success;
      case 'refusee':
      case 'annulee':
        return ReziTokens.danger;
      default:
        return ReziTokens.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune réservation.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.residenceTitre, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('${_df.format(r.dateDebut)} → ${_df.format(r.dateFin)}',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('${r.montant.toStringAsFixed(0)} FCFA',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: ReziTokens.accent)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statutColor(r.statut).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(ReziTokens.radiusSm),
                        ),
                        child: Text(
                          r.statut,
                          style: TextStyle(color: _statutColor(r.statut), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
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
