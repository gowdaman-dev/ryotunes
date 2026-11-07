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
import '../../widgets/artwork.dart';
import '../../widgets/feed_states.dart';
import '../../widgets/media_card.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/tinted_backdrop.dart';
import '../../widgets/track_row.dart';

/// An artist: round portrait, play/shuffle, their songs, and album / single / related shelves.
class ArtistScreen extends StatefulWidget {
  final String id;
  const ArtistScreen({super.key, required this.id});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  bool _showAllSongs = false;
  bool _fullBio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CatalogController>().loadArtist(widget.id));
  }

  List<SongItem> _songs(ArtistPage page, CatalogController catalog) => [...page.topSongs, ...catalog.moreSongs(page.id)];

  void _play(List<SongItem> songs, {int start = 0, bool shuffle = false}) {
    if (songs.isEmpty) return;
    final list = [...songs];
    if (shuffle) list.shuffle();
    context.read<PlayerController>().setQueue(list, start: shuffle ? 0 : start);
    context.push('/now-playing');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final player = context.watch<PlayerController>();
    final entry = catalog.artist(widget.id);
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
              SliverFillRemaining(hasScrollBody: false, child: Center(child: FeedError(message: "Couldn't load this artist.", onRetry: () => context.read<CatalogController>().loadArtist(widget.id, force: true))))
            else if (page == null)
              const SliverToBoxAdapter(child: _ArtistSkeleton())
            else
              SliverToBoxAdapter(child: _content(context, page, catalog, player, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ArtistPage page, CatalogController catalog, PlayerController player, ColorScheme scheme) {
    final songs = _songs(page, catalog);
    final visible = _showAllSongs ? songs : songs.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 36, offset: const Offset(0, 16))]),
            child: ClipOval(child: RemoteArt(url: page.thumbnail, width: 220, height: 220, placeholderIcon: Icons.person_rounded)),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
          child: SizedBox(
            width: double.infinity,
            child: Column(children: [
            Text(page.name, textAlign: TextAlign.center, style: RyFonts.display(32, color: scheme.onSurface)),
            if (page.audience != null) ...[
              const SizedBox(height: 4),
              Text(page.audience!, style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.55))),
            ],
          ]),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
          child: Row(children: [
            Expanded(child: PillButton(icon: Icons.play_arrow_rounded, label: 'Play', onTap: songs.isEmpty ? null : () => _play(songs))),
            const SizedBox(width: 12),
            Expanded(child: PillButton(icon: Icons.shuffle_rounded, label: 'Shuffle', onTap: songs.isEmpty ? null : () => _play(songs, shuffle: true))),
          ]),
        ),
        if (songs.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionHeader(title: 'Top Songs'),
          for (var i = 0; i < visible.length; i++)
            TrackRow(song: visible[i], index: i, playing: player.now?.videoId == visible[i].videoId, onTap: () => _play(songs, start: i)),
          if (songs.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
              child: TextButton(
                onPressed: () => setState(() => _showAllSongs = !_showAllSongs),
                child: Text(_showAllSongs ? 'Show fewer' : 'Show all ${songs.length} songs'),
              ),
            ),
        ],
        for (final section in page.sections) ...[
          const SizedBox(height: 24),
          SectionHeader(title: section.title),
          _Shelf(section: section),
        ],
        if (page.description != null) ...[
          const SizedBox(height: 28),
          const SectionHeader(title: 'About'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
            child: GestureDetector(
              onTap: () => setState(() => _fullBio = !_fullBio),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                alignment: Alignment.topCenter,
                child: Text(
                  page.description!,
                  maxLines: _fullBio ? null : 4,
                  overflow: _fullBio ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.7), height: 1.45),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: kShellBottomInset),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  final CatalogSection section;
  const _Shelf({required this.section});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
        itemCount: section.items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final item = section.items[i];
          return SquareCard(
            size: 160,
            round: item.isArtist,
            title: item.title,
            subtitle: item.subtitle,
            thumbnail: item.thumbnail,
            onTap: () => context.push(item.isArtist ? '/artist/${item.id}' : '/album/${item.id}'),
          );
        },
      ),
    );
  }
}

class _ArtistSkeleton extends StatelessWidget {
  const _ArtistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(children: [
        const SkeletonBox(width: 220, height: 220, circle: true),
        const SizedBox(height: 22),
        const SkeletonBox(width: 200, height: 30),
        const SizedBox(height: 10),
        const SkeletonBox(width: 120, height: 14),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.pagePad),
          child: Row(children: [Expanded(child: SkeletonBox(height: 50, radius: 14)), SizedBox(width: 12), Expanded(child: SkeletonBox(height: 50, radius: 14))]),
        ),
        const SizedBox(height: 28),
        for (var i = 0; i < 5; i++) SkeletonTrackRow(titleWidth: 150.0 + (i * 41 % 90)),
      ]),
    );
  }
}
