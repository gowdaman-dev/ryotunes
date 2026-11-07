import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/library_controller.dart';
import '../../providers/player_controller.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/artwork.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/song_menu.dart';
import '../../widgets/track_row.dart';

/// A user playlist (or Liked Songs): play, shuffle, rename, delete, remove songs by swiping.
class PlaylistScreen extends StatelessWidget {
  final String id;
  const PlaylistScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final library = context.watch<LibraryController>();
    final player = context.watch<PlayerController>();
    final playlist = library.byId(id);
    if (playlist == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Playlist not found')));
    }
    final songs = playlist.songs;
    final isLiked = id == LibraryController.likedId;

    void start({bool shuffle = false}) {
      if (songs.isEmpty) return;
      final queue = [...songs];
      if (shuffle) queue.shuffle();
      context.read<PlayerController>().setQueue(queue);
      context.push('/now-playing');
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: scheme.surface,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
            actions: [
              if (!isLiked)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (v) async {
                    final router = GoRouter.of(context);
                    final lib = context.read<LibraryController>();
                    if (v == 'rename') {
                      final name = await promptPlaylistName(context, title: 'Rename Playlist', initial: playlist.name, action: 'Save');
                      if (name != null) lib.rename(id, name);
                    } else {
                      lib.delete(id);
                      router.pop();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete Playlist')),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (isLiked)
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.hero),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFA2D48), Color(0xFFFF8A5B)]),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 72),
                  )
                else
                  ClipRRect(borderRadius: BorderRadius.circular(Radii.hero), child: Artwork(url: playlist.cover, size: 200, placeholderIcon: Icons.queue_music_rounded)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                  child: Text(playlist.name, textAlign: TextAlign.center, style: RyFonts.display(28, color: scheme.onSurface)),
                ),
                const SizedBox(height: 4),
                Text('${songs.length} ${songs.length == 1 ? 'song' : 'songs'}', style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
                  child: Row(children: [
                    Expanded(child: PillButton(icon: Icons.play_arrow_rounded, label: 'Play', onTap: songs.isEmpty ? null : start)),
                    const SizedBox(width: 12),
                    Expanded(child: PillButton(icon: Icons.shuffle_rounded, label: 'Shuffle', onTap: songs.isEmpty ? null : () => start(shuffle: true))),
                  ]),
                ),
                const SizedBox(height: 16),
                if (songs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Nothing here yet.\nTap ⋯ on any song and choose Add to Playlist.', textAlign: TextAlign.center, style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.5), height: 1.4)),
                  ),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: songs.length,
            itemBuilder: (_, i) {
              final s = songs[i];
              return Dismissible(
                key: ValueKey('${playlist.id}-${s.videoId}'),
                direction: DismissDirection.endToStart,
                background: Container(color: scheme.error, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), child: const Icon(Icons.delete_outline_rounded, color: Colors.white)),
                onDismissed: (_) => context.read<LibraryController>().removeSong(id, s.videoId),
                child: TrackRow(
                  song: s,
                  playing: player.now?.videoId == s.videoId,
                  onTap: () {
                    context.read<PlayerController>().setQueue(songs, start: i);
                    context.push('/now-playing');
                  },
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
