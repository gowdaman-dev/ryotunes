import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/library_controller.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/artwork.dart';
import '../../widgets/large_title_bar.dart';
import '../../widgets/song_menu.dart';

/// Library: Liked Songs plus the playlists the user has created.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final library = context.read<LibraryController>();
    final router = GoRouter.of(context);
    final name = await promptPlaylistName(context);
    if (name == null) return;
    router.push('/playlist/${library.create(name).id}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final library = context.watch<LibraryController>();
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: LargeTitleBar(title: 'Library')),
        SliverToBoxAdapter(
          child: InkWell(
            onTap: () => _create(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad, vertical: 8),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Radii.control)),
                  child: Icon(Icons.add_rounded, color: scheme.primary, size: 30),
                ),
                const SizedBox(width: 14),
                Text('New Playlist', style: RyFonts.ui(17, weight: FontWeight.w600, color: scheme.primary)),
              ]),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: library.playlists.length,
          itemBuilder: (_, i) {
            final p = library.playlists[i];
            final isLiked = p.id == LibraryController.likedId;
            return InkWell(
              onTap: () => context.push('/playlist/${p.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad, vertical: 8),
                child: Row(children: [
                  if (isLiked)
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.control),
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFA2D48), Color(0xFFFF8A5B)]),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white),
                    )
                  else
                    Artwork(url: p.cover, size: 56, placeholderIcon: Icons.queue_music_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(17, weight: FontWeight.w500, color: scheme.onSurface)),
                      Text('${p.songs.length} ${p.songs.length == 1 ? 'song' : 'songs'}', style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.55))),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.3)),
                ]),
              ),
            );
          },
        ),
        if (library.playlists.length == 1 && library.liked.songs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.pagePad, 32, Sp.pagePad, 0),
              child: Text(
                'Make your own playlists and like songs with the ⋯ menu on any track. They stay on this phone.',
                textAlign: TextAlign.center,
                style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.5), height: 1.4),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: kShellBottomInset)),
      ],
    );
  }
}
