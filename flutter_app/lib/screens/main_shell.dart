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

  static const _icons = [
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.calendar_month_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReziTokens.bg,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          // ── Nav flottante en pilule, façon référence ──
          Positioned(
            left: 24, right: 24, bottom: 20,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ReziTokens.radiusPill),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_icons.length, (i) {
                  final active = i == _index;
                  return GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: active ? ReziTokens.primaryGradient : null,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icons[i],
                        size: 20,
                        color: active ? Colors.white : ReziTokens.textMuted,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
