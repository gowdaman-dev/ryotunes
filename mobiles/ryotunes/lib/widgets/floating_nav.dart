import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/typography.dart';
import 'glass.dart';

class _Tab {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.path, this.label, this.icon, this.activeIcon);
}

const _tabs = [
  _Tab('/', 'Home', Icons.home_outlined, Icons.home_rounded),
  _Tab('/new', 'New', Icons.grid_view_outlined, Icons.grid_view_rounded),
  _Tab('/radio', 'Radio', Icons.sensors_rounded, Icons.sensors_rounded),
  _Tab('/library', 'Library', Icons.library_music_outlined, Icons.library_music_rounded),
];
const _searchPath = '/search';
const _detailPrefixes = ['/artist/', '/album/', '/playlist/'];

/// Floating glass tab bar: four tabs in a pill plus a detached search button.
class FloatingNav extends StatelessWidget {
  final String location;
  const FloatingNav({super.key, required this.location});

  int get _selected {
    if (location.startsWith(_searchPath)) return -1;
    if (_detailPrefixes.any(location.startsWith)) return -1;
    for (var i = 1; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected;
    final searching = location.startsWith(_searchPath);
    return Row(
      children: [
        Expanded(
          child: Glass(
            radius: 34,
            height: 68,
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      tab: _tabs[i],
                      selected: i == selected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.go(_tabs[i].path);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go(_searchPath);
          },
          child: Glass(
            radius: 34,
            width: 68,
            height: 68,
            child: Icon(Icons.search_rounded, size: 28, color: searching ? scheme.primary : scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, size: 25, color: color),
            const SizedBox(height: 2),
            Text(tab.label, style: RyFonts.ui(10.5, weight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
