// ═══════════════════════════════════════════════════════════════
// REZI — Design Tokens & Theme (Flutter / Material 3)
// Porté depuis index.html (:root CSS vars) — GARO21225/REZI
// Ajoute google_fonts au pubspec.yaml : google_fonts: ^6.2.1
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ── 1. TOKENS BRUTS (copie fidèle des variables CSS du site) ──
class ReziTokens {
  ReziTokens._();

  // Dark (thème par défaut du site : color-scheme: dark)
  static const darkBg = Color(0xFF0B0F1A);
  static const darkSurface = Color(0xFF131929);
  static const darkSurface2 = Color(0xFF1C2640);
  static const darkBorder = Color(0xFF243156);
  static const darkText = Color(0xFFE8EDF8);
  static const darkTextMuted = Color(0xFF7A8AAA);

  // Light
  static const lightBg = Color(0xFFF5F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFEEF0F7);
  static const lightBorder = Color(0xFFDDE1EF);
  static const lightText = Color(0xFF1A2035);
  static const lightTextMuted = Color(0xFF6B7A99);

  // Communes aux deux thèmes
  static const accent = Color(0xFFF5A623);   // orange
  static const accent2 = Color(0xFFE8855A);  // corail
  static const success = Color(0xFF3ECF8E);
  static const danger = Color(0xFFE25555);

  // Rayons observés dans le CSS (9–12px selon composant)
  static const radiusSm = 7.0;
  static const radiusMd = 9.0;
  static const radiusLg = 12.0;

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );
}

/// ── 2. THEMES ──
class ReziTheme {
  ReziTheme._();

  static TextTheme _textTheme(Color text, Color muted) {
    final base = GoogleFonts.dmSansTextTheme();
    return base.copyWith(
      // Playfair Display réservé aux titres de marque (logo, hero)
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 28, fontWeight: FontWeight.w900, color: text, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: text),
      titleMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: text),
      bodyLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: text),
      bodyMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: text),
    );
  }

  static ThemeData get dark {
    const cs = ColorScheme.dark(
      primary: ReziTokens.accent,
      secondary: ReziTokens.accent2,
      surface: ReziTokens.darkSurface,
      error: ReziTokens.danger,
      onPrimary: Colors.white,
      onSurface: ReziTokens.darkText,
      outline: ReziTokens.darkBorder,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: ReziTokens.darkBg,
      textTheme: _textTheme(ReziTokens.darkText, ReziTokens.darkTextMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: ReziTokens.darkSurface,
        foregroundColor: ReziTokens.darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: ReziTokens.darkBorder)),
      ),
      cardTheme: CardThemeData(
        color: ReziTokens.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
          side: const BorderSide(color: ReziTokens.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReziTokens.darkSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
          borderSide: const BorderSide(color: ReziTokens.darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
          borderSide: const BorderSide(color: ReziTokens.accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: ReziTokens.darkTextMuted, fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReziTokens.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReziTokens.radiusMd)),
          textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ReziTokens.darkText,
          side: const BorderSide(color: ReziTokens.darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReziTokens.radiusMd)),
        ),
      ),
      dividerColor: ReziTokens.darkBorder,
    );
  }

  static ThemeData get light {
    const cs = ColorScheme.light(
      primary: ReziTokens.accent,
      secondary: ReziTokens.accent2,
      surface: ReziTokens.lightSurface,
      error: ReziTokens.danger,
      onPrimary: Colors.white,
      onSurface: ReziTokens.lightText,
      outline: ReziTokens.lightBorder,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: ReziTokens.lightBg,
      textTheme: _textTheme(ReziTokens.lightText, ReziTokens.lightTextMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: ReziTokens.lightSurface,
        foregroundColor: ReziTokens.lightText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: ReziTokens.lightBorder)),
      ),
      cardTheme: CardThemeData(
        color: ReziTokens.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusLg),
          side: const BorderSide(color: ReziTokens.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReziTokens.lightSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
          borderSide: const BorderSide(color: ReziTokens.lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
          borderSide: const BorderSide(color: ReziTokens.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReziTokens.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReziTokens.radiusMd)),
        ),
      ),
      dividerColor: ReziTokens.lightBorder,
    );
  }
}

/// ── 3. WIDGETS RÉUTILISABLES clés du site (logo, bouton dégradé, avatar) ──

/// Reproduit .logo-icon : carré dégradé accent→accent2, coins arrondis 9px
class ReziLogoBadge extends StatelessWidget {
  final double size;
  const ReziLogoBadge({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: ReziTokens.accentGradient,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.home_rounded, size: size * 0.5, color: Colors.white),
    );
  }
}

/// Reproduit .btn-primary : dégradé + hover(elevation) → ici un splash + shadow léger
class ReziPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const ReziPrimaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: ReziTokens.accentGradient,
        borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: ReziTokens.accent.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reproduit .avatar : cercle dégradé avec initiales
class ReziAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const ReziAvatar({super.key, required this.initials, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: ReziTokens.accentGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
