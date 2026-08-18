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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
        border: Border.all(color: ReziTokens.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  residence.photos.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: residence.photos.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: ReziTokens.surface2),
                          errorWidget: (_, __, ___) => Container(
                            color: ReziTokens.surface2,
                            child: const Icon(Icons.image_not_supported_outlined, color: ReziTokens.textMuted),
                          ),
                        )
                      : Container(color: ReziTokens.surface2),
                  // ── Statut ("Active"/"Indisponible") en haut à gauche ──
                  Positioned(
                    top: 10, left: 10,
                    child: ReziStatusPill(
                      label: residence.disponible ? 'Active' : 'Indisponible',
                      color: residence.disponible ? ReziTokens.primary : ReziTokens.danger,
                    ),
                  ),
                  // ── Prix, pastille sombre en bas à droite de la photo ──
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(ReziTokens.radiusSm),
                      ),
                      child: Text(
                        '${residence.prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(residence.titre,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      GestureDetector(
                        onTap: () => onToggleFavori?.call(!isFavori),
                        child: Icon(
                          isFavori ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 20,
                          color: isFavori ? ReziTokens.primary : ReziTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: ReziTokens.accent),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(residence.adresse ?? residence.type,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MetaTag(icon: Icons.home_work_outlined, label: residence.type),
                      if (residence.note != null) ...[
                        const SizedBox(width: 8),
                        _MetaTag(icon: Icons.star_rounded, label: residence.note!.toStringAsFixed(1),
                            iconColor: ReziTokens.accent),
                      ],
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

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _MetaTag({required this.icon, required this.label, this.iconColor = ReziTokens.textMuted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: ReziTokens.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
