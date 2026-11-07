import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/song.dart';
import '../../providers/player_controller.dart';
import '../../providers/trending_controller.dart';
import '../../theme/spacing.dart';
import '../../widgets/feed_states.dart';
import '../../widgets/large_title_bar.dart';
import '../../widgets/media_card.dart';
import '../../widgets/ry_chip.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/track_row.dart';

/// New is discovery: fresh releases, the language's top-songs chart, and extra finds.
/// (Home is the personal screen.)
class NewScreen extends StatefulWidget {
  const NewScreen({super.key});
  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = context.read<TrendingController>();
      t.loadNew(t.language);
      t.loadTrending(t.language);
    });
  }

  void _play(List<SongItem> songs, int i) {
    context.read<PlayerController>().setQueue(songs, start: i);
    context.push('/now-playing');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TrendingController>();
    final player = context.watch<PlayerController>();
    final fresh = t.fresh();
    final chart = t.trending();
    final heroWidth = (MediaQuery.of(context).size.width - Sp.pagePad * 2 - 24).clamp(200.0, 600.0);
    final releases = fresh.songs.take(6).toList();
    final finds = fresh.songs.skip(6).take(12).toList();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: LargeTitleBar(title: 'New')),
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
                    return RyChip(label: lang, selected: t.language == lang, onTap: () => context.read<TrendingController>().select(lang));
                  },
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(title: 'New Releases', eyebrow: '${t.language} · latest'),
              if (releases.isEmpty && fresh.status != FeedStatus.failed)
                SkeletonHero(width: heroWidth, height: heroWidth * 1.05)
              else if (releases.isEmpty)
                FeedError(onRetry: () => context.read<TrendingController>().loadNew(t.language, force: true))
              else
                SizedBox(
                  height: heroWidth * 1.05 + 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                    itemCount: releases.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => HeroCard(
                      width: heroWidth,
                      height: heroWidth * 1.05,
                      eyebrow: i == 0 ? 'Just added' : 'New release',
                      title: releases[i].title,
                      caption: releases[i].artists,
                      thumbnail: releases[i].thumbnail,
                      onTap: () => _play(releases, i),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              SectionHeader(title: 'Top Songs', eyebrow: '${t.language} chart'),
              if (chart.songs.isEmpty && chart.status != FeedStatus.failed)
                const SkeletonTrackList(count: 8)
              else if (chart.songs.isEmpty)
                FeedError(onRetry: () => context.read<TrendingController>().loadTrending(t.language, force: true))
              else
                for (var i = 0; i < chart.songs.length.clamp(0, 20); i++)
                  TrackRow(song: chart.songs[i], index: i, playing: player.now?.videoId == chart.songs[i].videoId, onTap: () => _play(chart.songs, i)),
              if (finds.isNotEmpty || (fresh.songs.isEmpty && fresh.status != FeedStatus.failed)) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Fresh Finds'),
                if (finds.isEmpty)
                  const SkeletonCardRow()
                else
                  SizedBox(
                    height: 214,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                      itemCount: finds.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => SquareCard(size: 160, title: finds[i].title, subtitle: finds[i].artists, thumbnail: finds[i].thumbnail, onTap: () => _play(finds, i)),
                    ),
                  ),
              ],
              const SizedBox(height: kShellBottomInset),
            ],
          ),
        ),
      ],
    );
  }
}
