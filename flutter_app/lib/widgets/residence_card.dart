import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/residence.dart';
import '../theme/rezi_theme.dart';

/// Card éditoriale minimaliste, façon référence : pas de cadre, photo pleine,
/// pastille note en haut à gauche, titre + sous-titre en dessous.
class ResidenceCard extends StatelessWidget {
  final Residence residence;
  final VoidCallback onTap;
  final bool isFavori;
  final ValueChanged<bool>? onToggleFavori;
  final double photoAspectRatio;

  const ResidenceCard({
    super.key,
    required this.residence,
    required this.onTap,
    this.isFavori = false,
    this.onToggleFavori,
    this.photoAspectRatio = 1.0,
  });

  static const _pillColors = [
    ReziTokens.primary, Color(0xFF7A8B3F), Color(0xFFC98A4B), ReziTokens.primaryLight,
  ];

  @override
  Widget build(BuildContext context) {
    final pillColor = _pillColors[residence.id.hashCode.abs() % _pillColors.length];
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: photoAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                  child: Hero(
                    tag: 'residence-photo-${residence.id}',
                    child: residence.photos.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: residence.photos.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const _ShimmerBox(),
                            errorWidget: (_, __, ___) => Container(
                              color: ReziTokens.surface2,
                              child: const Icon(Icons.image_not_supported_outlined, color: ReziTokens.textMuted),
                            ),
                          )
                        : Container(color: ReziTokens.surface2),
                  ),
                ),
                // ── Pastille note, en haut à gauche façon référence ("5.0") ──
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(ReziTokens.radiusSm)),
                    child: Text(
                      residence.note?.toStringAsFixed(1) ?? '—',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (!residence.disponible)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
                      ),
                    ),
                  ),
                // ── Favori discret en haut à droite ──
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => onToggleFavori?.call(!isFavori),
                    child: AnimatedScale(
                      scale: isFavori ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                        child: Icon(
                          isFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: isFavori ? ReziTokens.accent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(residence.titre,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            residence.description?.isNotEmpty == true ? residence.description! : residence.type,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final dx = bounds.width * 2 * _ctrl.value - bounds.width * 0.5;
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [ReziTokens.surface2, Colors.white, ReziTokens.surface2],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideGradient(dx),
          ).createShader(bounds);
        },
        child: Container(color: ReziTokens.surface2),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
}

/// Fait apparaître son enfant en fondu + léger glissement, avec un délai
/// proportionnel à [index] — donne l'effet d'entrée "en cascade" à une grille.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggeredEntrance({super.key, required this.index, required this.child});

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * (widget.index % 10)), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
