import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/catalog.dart';
import '../../models/song.dart';
import '../../providers/catalog_controller.dart';
import '../../providers/player_controller.dart';
import '../../providers/trending_controller.dart' show FeedStatus;
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../util/navigation.dart';
import '../../widgets/artwork.dart';
import '../../widgets/feed_states.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/tinted_backdrop.dart';
import '../../widgets/track_row.dart';

/// An album, single or EP: cover, credits, play/shuffle and the numbered track list.
class AlbumScreen extends StatefulWidget {
  final String id;
  const AlbumScreen({super.key, required this.id});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CatalogController>().loadAlbum(widget.id));
  }

  void _play(List<SongItem> songs, {int start = 0, bool shuffle = false}) {
    if (songs.isEmpty) return;
    final list = [...songs];
    if (shuffle) list.shuffle();
    context.read<PlayerController>().setQueue(list, start: shuffle ? 0 : start);
    context.push('/now-playing');
  }

  @override
  Widget build(BuildContext context) {
    final entry = context.watch<CatalogController>().album(widget.id);
    final player = context.watch<PlayerController>();
    final page = entry.data;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: TintedBackdrop(
        imageUrl: page?.thumbnail,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leadingWidth: 60,
              leading: const Center(child: RoundBackButton()),
              toolbarHeight: 64,
            ),
            if (page == null && entry.status == FeedStatus.failed)
              SliverFillRemaining(hasScrollBody: false, child: Center(child: FeedError(message: "Couldn't load this album.", onRetry: () => context.read<CatalogController>().loadAlbum(widget.id, force: true))))
            else if (page == null)
              const SliverToBoxAdapter(child: _AlbumSkeleton())
            else
              SliverToBoxAdapter(child: _content(context, page, player, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AlbumPage page, PlayerController player, ColorScheme scheme) {
    final meta = [if (page.type != null) page.type!, if (page.year != null) page.year!].join(' · ');
    return Column(
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.hero), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 36, offset: const Offset(0, 16))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(Radii.hero), child: RemoteArt(url: page.thumbnail, width: 240, height: 240, placeholderIcon: Icons.album_rounded)),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
          child: Column(children: [
            Text(page.title, textAlign: TextAlign.center, style: RyFonts.display(26, color: scheme.onSurface)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: page.artistRefs.isEmpty ? null : () => page.artistRefs.length == 1 ? openArtist(context, page.artistRefs.first.id) : openArtistOf(context, SongItem(videoId: '', title: '', artists: page.artist, artistRefs: page.artistRefs)),
              child: Text(page.artist, textAlign: TextAlign.center, style: RyFonts.ui(18, weight: FontWeight.w600, color: scheme.primary)),
            ),
            const SizedBox(height: 4),
            Text([if (meta.isNotEmpty) meta, if (page.info != null) page.info!].join('\n'), textAlign: TextAlign.center, style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface.withValues(alpha: 0.55), height: 1.4)),
          ]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
          child: Row(children: [
            Expanded(child: PillButton(icon: Icons.play_arrow_rounded, label: 'Play', onTap: page.tracks.isEmpty ? null : () => _play(page.tracks))),
            const SizedBox(width: 12),
            Expanded(child: PillButton(icon: Icons.shuffle_rounded, label: 'Shuffle', onTap: page.tracks.isEmpty ? null : () => _play(page.tracks, shuffle: true))),
          ]),
        ),
        const SizedBox(height: 12),
        if (page.tracks.isEmpty)
          Padding(padding: const EdgeInsets.all(40), child: Text('No playable tracks on this release.', style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.5)))),
        for (var i = 0; i < page.tracks.length; i++)
          TrackRow(song: page.tracks[i], index: i, showArtwork: false, playing: player.now?.videoId == page.tracks[i].videoId, onTap: () => _play(page.tracks, start: i)),
        const SizedBox(height: kShellBottomInset),
      ],
    );
  }
}

class _AlbumSkeleton extends StatelessWidget {
  const _AlbumSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(children: [
        const SkeletonBox(width: 240, height: 240, radius: Radii.hero),
        const SizedBox(height: 22),
        const SkeletonBox(width: 220, height: 26),
        const SizedBox(height: 10),
        const SkeletonBox(width: 140, height: 16),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.pagePad),
          child: Row(children: [Expanded(child: SkeletonBox(height: 50, radius: 14)), SizedBox(width: 12), Expanded(child: SkeletonBox(height: 50, radius: 14))]),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 6; i++) SkeletonTrackRow(titleWidth: 150.0 + (i * 37 % 90)),
      ]),
    );
  }
}
