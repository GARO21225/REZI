import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favoris_screen.dart';
import 'mes_reservations_screen.dart';
import 'conversations_screen.dart';
import 'profil_screen.dart';
import '../theme/rezi_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    FavorisScreen(),
    MesReservationsScreen(),
    ConversationsScreen(),
    ProfilScreen(),
  ];

  static const _items = [
    (Icons.home_rounded, 'Accueil'),
    (Icons.favorite_rounded, 'Favoris'),
    (Icons.calendar_month_rounded, 'Réservations'),
    (Icons.chat_bubble_rounded, 'Messages'),
    (Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReziTokens.bg,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          // ── Nav flottante avec icônes + labels, façon référence ──
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final active = i == _index;
                  final (icon, label) = _items[i];
                  return GestureDetector(
                    onTap: () => setState(() => _index = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: active ? ReziTokens.primaryGradient : null,
                        borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20, color: active ? Colors.white : ReziTokens.textMuted),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: active
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(label,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
