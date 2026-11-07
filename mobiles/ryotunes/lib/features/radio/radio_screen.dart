import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/player_controller.dart';
import '../../providers/trending_controller.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/large_title_bar.dart';

class _Station {
  final String name;
  final String tagline;
  final String language;
  final List<Color> colors;
  const _Station(this.name, this.tagline, this.language, this.colors);
}

const _stations = [
  _Station('Kollywood Hits', 'Tamil · Now trending', 'Tamil', [Color(0xFFFA2D48), Color(0xFFFF8A5B)]),
  _Station('Tollywood Beats', 'Telugu · Chart toppers', 'Telugu', [Color(0xFF7B5CC4), Color(0xFF4F7BE8)]),
  _Station('Mollywood Melodies', 'Malayalam · Fresh picks', 'Malayalam', [Color(0xFF1FA67A), Color(0xFF8BD17C)]),
  _Station('Sandalwood Select', 'Kannada · Popular now', 'Kannada', [Color(0xFFEF9F1C), Color(0xFFF5576C)]),
];

/// Radio: one-tap stations that play each language's live trending chart.
class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  Future<void> _start(BuildContext context, _Station s) async {
    final trending = context.read<TrendingController>();
    final player = context.read<PlayerController>();
    final router = GoRouter.of(context);
    await trending.loadTrending(s.language);
    final songs = trending.songsFor(s.language);
    if (songs.isEmpty) return;
    player.setQueue(songs, start: 0);
    router.push('/now-playing');
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: LargeTitleBar(title: 'Radio', subtitle: 'Endless South Indian hits, ad-free')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Sp.pagePad, 4, Sp.pagePad, kShellBottomInset),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.9),
            itemCount: _stations.length,
            itemBuilder: (_, i) {
              final s = _stations[i];
              return GestureDetector(
                onTap: () => _start(context, s),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.hero),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s.colors),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(999)),
                        child: Text('LIVE', style: RyFonts.ui(10, weight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                      ),
                      const Spacer(),
                      Icon(Icons.sensors_rounded, color: Colors.white.withValues(alpha: 0.9), size: 34),
                      const SizedBox(height: 8),
                      Text(s.name, maxLines: 2, style: RyFonts.ui(20, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4, height: 1.1)),
                      const SizedBox(height: 4),
                      Text(s.tagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(TypeScale.sm, color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
