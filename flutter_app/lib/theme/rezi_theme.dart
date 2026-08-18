// ═══════════════════════════════════════════════════════════════
// REZI — Design Tokens & Theme v2 (Flutter / Material 3)
// Direction artistique : crème + vert forêt, éditorial, "Waou"
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReziTokens {
  ReziTokens._();

  // Palette claire (crème / vert forêt)
  static const bg = Color(0xFFF7F5EF);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEFEEE6);
  static const border = Color(0xFFE3E0D4);
  static const text = Color(0xFF1B2A22);
  static const textMuted = Color(0xFF6B7A70);

  static const primary = Color(0xFF2F5233);   // vert forêt profond
  static const primaryLight = Color(0xFF3E6B45);
  static const primarySoft = Color(0xFFE7EEE3); // fond pastille verte claire

  static const accent = Color(0xFFC98A4B);   // terracotta chaud (accents secondaires)
  static const success = Color(0xFF3ECF8E);
  static const danger = Color(0xFFD65B4A);

  static const radiusSm = 10.0;
  static const radiusMd = 16.0;
  static const radiusLg = 26.0;
  static const radiusPill = 999.0;

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static Color disponibleBadgeColor(bool disponible) => disponible ? primary : danger;
}

class ReziTheme {
  ReziTheme._();

  static TextTheme get _textTheme {
    final base = GoogleFonts.dmSansTextTheme();
    return base.copyWith(
      // Serif éditoriale bold pour les grandes accroches, comme la référence.
      displayLarge: GoogleFonts.fraunces(
        fontSize: 34, fontWeight: FontWeight.w700, color: ReziTokens.text, height: 1.1, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 24, fontWeight: FontWeight.w700, color: ReziTokens.text, height: 1.15,
      ),
      titleLarge: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: ReziTokens.text),
      titleMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: ReziTokens.text),
      bodyLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: ReziTokens.text),
      bodyMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: ReziTokens.textMuted),
      labelLarge: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: ReziTokens.text),
    );
  }

  static ThemeData get light {
    const cs = ColorScheme.light(
      primary: ReziTokens.primary,
      secondary: ReziTokens.accent,
      surface: ReziTokens.surface,
      error: ReziTokens.danger,
      onPrimary: Colors.white,
      onSurface: ReziTokens.text,
      outline: ReziTokens.border,
      surfaceContainerHighest: ReziTokens.surface2,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: ReziTokens.bg,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ReziTokens.bg,
        foregroundColor: ReziTokens.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: ReziTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
          side: const BorderSide(color: ReziTokens.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReziTokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
          borderSide: const BorderSide(color: ReziTokens.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
          borderSide: const BorderSide(color: ReziTokens.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
          borderSide: const BorderSide(color: ReziTokens.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: ReziTokens.textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReziTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReziTokens.radiusPill)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ReziTokens.text,
          side: const BorderSide(color: ReziTokens.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReziTokens.radiusPill)),
        ),
      ),
      dividerColor: ReziTokens.border,
    );
  }
}

/// ── Widgets réutilisables (identité visuelle REZI) ──

class ReziLogoBadge extends StatelessWidget {
  final double size;
  const ReziLogoBadge({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: ReziTokens.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.home_rounded, size: size * 0.5, color: Colors.white),
    );
  }
}

class ReziPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  const ReziPrimaryButton({
    super.key, required this.label, this.onPressed, this.icon, this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: disabled ? ReziTokens.textMuted.withValues(alpha: 0.3) : null,
        gradient: disabled ? null : ReziTokens.primaryGradient,
        borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton d'action circulaire vert plein — flèche façon référence détail.
class ReziCircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  const ReziCircleActionButton({super.key, required this.icon, this.onPressed, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ReziTokens.primaryGradient, shape: BoxShape.circle),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size, height: size,
            child: Icon(icon, color: Colors.white, size: size * 0.42),
          ),
        ),
      ),
    );
  }
}

class ReziAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const ReziAvatar({super.key, required this.initials, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: ReziTokens.primaryGradient, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.dmSans(fontSize: size * 0.34, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

/// Icône ronde blanche (flottante sur les images), façon bouton retour/partage référence.
class ReziGhostIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  const ReziGhostIconButton({super.key, required this.icon, this.onTap, this.iconColor = ReziTokens.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

/// Pastille de statut (ex : "Active"), façon référence card.
class ReziStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const ReziStatusPill({super.key, required this.label, this.color = ReziTokens.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(ReziTokens.radiusPill)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
