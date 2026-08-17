import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/residence.dart';
import '../theme/rezi_theme.dart';

class ResidenceCard extends StatelessWidget {
  final Residence residence;
  final VoidCallback onTap;

  const ResidenceCard({super.key, required this.residence, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  residence.photos.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: residence.photos.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                          errorWidget: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      : Container(color: cs.surfaceContainerHighest),
                  if (!residence.disponible)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ReziTokens.danger,
                          borderRadius: BorderRadius.circular(ReziTokens.radiusSm),
                        ),
                        child: const Text('Indisponible',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(residence.titre,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(residence.type, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${residence.prix.toStringAsFixed(0)} FCFA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ReziTokens.accent),
                      ),
                      if (residence.note != null)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: ReziTokens.accent),
                            const SizedBox(width: 2),
                            Text(residence.note!.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
