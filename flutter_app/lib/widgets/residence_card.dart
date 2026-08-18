import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/residence.dart';
import '../theme/rezi_theme.dart';

class ResidenceCard extends StatelessWidget {
  final Residence residence;
  final VoidCallback onTap;
  final bool isFavori;
  final ValueChanged<bool>? onToggleFavori;

  const ResidenceCard({
    super.key,
    required this.residence,
    required this.onTap,
    this.isFavori = false,
    this.onToggleFavori,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                    child: residence.photos.isNotEmpty
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
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (!residence.disponible)
                    Positioned(
                      top: 10, left: 10,
                      child: _Badge(
                        color: ReziTokens.danger,
                        child: const Text('Indisponible',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (residence.note != null)
                    Positioned(
                      top: 10, left: 10,
                      child: _Badge(
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: ReziTokens.accent),
                            const SizedBox(width: 3),
                            Text(residence.note!.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => onToggleFavori?.call(!isFavori),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFavori ? ReziTokens.accent2 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10, bottom: 10,
                    child: Text(
                      '${residence.prix.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(residence.titre,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(residence.adresse ?? residence.type,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium),
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

class _Badge extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Badge({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(ReziTokens.radiusSm)),
      child: child,
    );
  }
}
