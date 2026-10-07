import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';
import 'alphabet_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'review_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark = state.profile.theme == 'dark';
    final reviewCount = state.review.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: context.cs.primary, borderRadius: BorderRadius.circular(12)),
              child: const Text('한', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hangul Quest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                Text('KOREAN FROM ZERO',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: context.hq.muted)),
              ],
            ),
          ],
        ),
        actions: [
          _Chip(icon: Icons.local_fire_department_rounded, text: '${state.profile.streak}', color: context.hq.warn),
          const SizedBox(width: 6),
          _Chip(icon: Icons.bolt_rounded, text: '${state.profile.xpBalance}', color: context.cs.primary),
          const SizedBox(width: 6),
          IconButton(
            tooltip: dark ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: () => state.setTheme(dark ? 'light' : 'dark'),
            icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          AlphabetScreen(),
          ReviewScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 66,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Path'),
          const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Hangul'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: reviewCount > 0,
              label: Text(reviewCount > 9 ? '9+' : '$reviewCount'),
              child: const Icon(Icons.menu_book_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: reviewCount > 0,
              label: Text(reviewCount > 9 ? '9+' : '$reviewCount'),
              child: const Icon(Icons.menu_book_rounded),
            ),
            label: 'Review',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'You'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.hq.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
