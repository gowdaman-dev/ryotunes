import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/song.dart';
import '../../providers/library_controller.dart';
import '../../providers/player_controller.dart';
import '../../providers/trending_controller.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/artwork.dart';
import '../../widgets/feed_states.dart';
import '../../widgets/large_title_bar.dart';
import '../../widgets/media_card.dart';
import '../../widgets/ry_chip.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/track_row.dart';

/// Home is personal: what you played, your playlists, and picks seeded from your own listening.
/// (Discovery of new releases and charts lives on the New tab.)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _requestedSeeds = {};

  /// Lead artists of the most recent plays, newest first, no repeats.
  List<String> _seedArtists(List<SongItem> recent) {
    final seen = <String>{};
    for (final s in recent) {
      final lead = s.artists.split(RegExp(r',|&')).first.trim();
      if (lead.isNotEmpty) seen.add(lead);
      if (seen.length == 1) break;
    }
    return seen.toList();
  }

  void _play(List<SongItem> songs, int i) {
    context.read<PlayerController>().setQueue(songs, start: i);
    context.push('/now-playing');
  }

  @override
  Widget build(BuildContext context) {
    final trending = context.watch<TrendingController>();
    final library = context.watch<LibraryController>();
    final player = context.watch<PlayerController>();
    final recent = library.recent;
    final seeds = _seedArtists(recent);
    for (final a in seeds) {
      if (_requestedSeeds.add(a)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => context.read<TrendingController>().loadArtist(a));
      }
    }

    // The selected language's trending songs always lead Home; personal rows come after.
    final top = trending.trending();
    final seedFeed = seeds.isNotEmpty ? trending.artist(seeds.first) : null;
    final cardWidth = (MediaQuery.of(context).size.width - Sp.pagePad * 2 - 24).clamp(200.0, 600.0);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');
    final yourPlaylists = library.playlists;
    const heroCount = 8;
    final moreTrending = top.songs.skip(heroCount).take(7).toList();

    return CustomScrollView(
      cacheExtent: 800,
      slivers: [
        SliverToBoxAdapter(child: LargeTitleBar(showLogo: true, title: 'Home', subtitle: recent.isEmpty ? '$greeting · play something and Home learns your taste' : greeting)),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                  itemCount: trendingLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final lang = trendingLanguages[i];
                    return RyChip(label: lang, selected: trending.language == lang, onTap: () => context.read<TrendingController>().select(lang));
                  },
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Trending in ${trending.language}', eyebrow: 'Updated daily'),
              if (top.songs.isEmpty && top.status != FeedStatus.failed)
                SkeletonHero(width: cardWidth, height: cardWidth)
              else if (top.songs.isEmpty)
                FeedError(onRetry: () => context.read<TrendingController>().loadTrending(trending.language, force: true))
              else
                SizedBox(
                  height: cardWidth + 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                    itemCount: top.songs.length.clamp(0, heroCount),
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final s = top.songs[i];
                      return HeroCard(
                        width: cardWidth,
                        height: cardWidth,
                        eyebrow: '#${i + 1} trending in ${trending.language}',
                        title: s.title,
                        caption: s.artists,
                        thumbnail: s.thumbnail,
                        onTap: () => _play(top.songs, i),
                      );
                    },
                  ),
                ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 28),
                const SectionHeader(title: 'Recently Played'),
                SizedBox(
                  height: 214,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => SquareCard(size: 160, title: recent[i].title, subtitle: recent[i].artists, thumbnail: recent[i].thumbnail, onTap: () => _play(recent, i)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SectionHeader(title: 'Your Playlists', onTap: () => context.go('/library')),
              SizedBox(
                height: 214,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                  itemCount: yourPlaylists.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    if (i == yourPlaylists.length) return _NewPlaylistTile(onTap: () => context.go('/library'));
                    final p = yourPlaylists[i];
                    final liked = p.id == LibraryController.likedId;
                    return _PlaylistCard(
                      title: p.name,
                      subtitle: '${p.songs.length} ${p.songs.length == 1 ? 'song' : 'songs'}',
                      cover: p.cover,
                      liked: liked,
                      onTap: () => context.push('/playlist/${p.id}'),
                    );
                  },
                ),
              ),
              if (seedFeed != null && seedFeed.status == FeedStatus.ready) ...[
                const SizedBox(height: 20),
                SectionHeader(title: 'Because you played ${seeds.first}'),
                for (var i = 0; i < seedFeed.songs.length.clamp(0, 5); i++)
                  TrackRow(song: seedFeed.songs[i], playing: player.now?.videoId == seedFeed.songs[i].videoId, onTap: () => _play(seedFeed.songs, i)),
              ],
              if (moreTrending.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionHeader(title: 'More trending in ${trending.language}', eyebrow: 'See the full chart on New', onTap: () => context.go('/new')),
                for (var i = 0; i < moreTrending.length; i++)
                  TrackRow(song: moreTrending[i], playing: player.now?.videoId == moreTrending[i].videoId, onTap: () => _play(top.songs, heroCount + i)),
              ],
              const SizedBox(height: kShellBottomInset),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? cover;
  final bool liked;
  final VoidCallback onTap;
  const _PlaylistCard({required this.title, required this.subtitle, required this.cover, required this.liked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 160.0;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.card),
            child: liked
                ? Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFA2D48), Color(0xFFFF8A5B)])),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 52),
                  )
                : RemoteArt(url: cover, width: size, height: size, placeholderIcon: Icons.queue_music_rounded),
          ),
          const SizedBox(height: 8),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
          Text(subtitle, style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface.withValues(alpha: 0.55))),
        ]),
      ),
    );
  }
}

class _NewPlaylistTile extends StatelessWidget {
  final VoidCallback onTap;
  const _NewPlaylistTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Radii.card)),
            child: Icon(Icons.add_rounded, color: scheme.primary, size: 44),
          ),
          const SizedBox(height: 8),
          Text('New Playlist', style: RyFonts.ui(TypeScale.md, weight: FontWeight.w600, color: scheme.primary)),
        ]),
      ),
    );
  }
}
