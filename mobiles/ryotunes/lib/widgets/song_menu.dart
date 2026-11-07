import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_controller.dart';
import '../providers/player_controller.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../util/navigation.dart';
import 'artwork.dart';

/// Name prompt used for creating and renaming playlists. Returns null when cancelled.
Future<String?> promptPlaylistName(BuildContext context, {String title = 'New Playlist', String initial = '', String action = 'Create'}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()), child: Text(action)),
      ],
    ),
  );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.fromLTRB(16, 0, 16, 180)));
}

/// "⋯" menu for a song: queue actions, like, and add to any of the user's playlists.
Future<void> showSongMenu(BuildContext context, SongItem song, {bool fromPlayer = false, List<(IconData, String, VoidCallback)> extra = const []}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    builder: (sheetCtx) {
      final scheme = Theme.of(sheetCtx).colorScheme;
      final library = sheetCtx.read<LibraryController>();
      final player = sheetCtx.read<PlayerController>();
      final liked = library.isLiked(song.videoId);
      Widget tile(IconData icon, String label, VoidCallback onTap) => ListTile(
            leading: Icon(icon),
            title: Text(label, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
            onTap: () {
              Navigator.pop(sheetCtx);
              onTap();
            },
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.pagePad, 18, Sp.pagePad, 8),
              child: Row(children: [
                Artwork(url: song.thumbnail, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(16, weight: FontWeight.w600, color: scheme.onSurface)),
                    Text(song.artists, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.55))),
                  ]),
                ),
              ]),
            ),
            const Divider(),
            tile(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, liked ? 'Remove from Liked Songs' : 'Add to Liked Songs', () {
              library.toggleLike(song);
              _toast(context, liked ? 'Removed from Liked Songs' : 'Added to Liked Songs');
            }),
            tile(Icons.playlist_add_rounded, 'Add to Playlist', () => _pickPlaylist(context, song)),
            tile(Icons.queue_play_next_rounded, 'Play Next', () {
              player.playNext(song);
              _toast(context, 'Playing next');
            }),
            tile(Icons.playlist_play_rounded, 'Add to Queue', () {
              player.addToQueue(song);
              _toast(context, 'Added to queue');
            }),
            if (song.artistRefs.isNotEmpty) tile(Icons.person_outline_rounded, song.artistRefs.length > 1 ? 'Go to Artist…' : 'Go to Artist', () => openArtistOf(context, song, closePlayer: fromPlayer)),
            if (song.albumId != null) tile(Icons.album_outlined, 'Go to Album', () => openAlbum(context, song.albumId!, closePlayer: fromPlayer)),
            for (final e in extra) tile(e.$1, e.$2, e.$3),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _pickPlaylist(BuildContext context, SongItem song) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    builder: (sheetCtx) {
      final scheme = Theme.of(sheetCtx).colorScheme;
      return Consumer<LibraryController>(
        builder: (_, library, __) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.pagePad, 20, Sp.pagePad, 8),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Add to Playlist', style: RyFonts.ui(22, weight: FontWeight.w700, color: scheme.onSurface))),
                ),
                ListTile(
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Radii.control)),
                    child: Icon(Icons.add_rounded, color: scheme.primary),
                  ),
                  title: Text('New Playlist', style: RyFonts.ui(TypeScale.md, weight: FontWeight.w600, color: scheme.primary)),
                  onTap: () async {
                    final name = await promptPlaylistName(sheetCtx);
                    if (name == null) return;
                    library.create(name, firstSong: song);
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    if (context.mounted) _toast(context, 'Added to $name');
                  },
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in library.playlists)
                        ListTile(
                          leading: p.id == LibraryController.likedId
                              ? Container(width: 48, height: 48, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(Radii.control)), child: const Icon(Icons.favorite_rounded, color: Colors.white))
                              : Artwork(url: p.cover, size: 48, placeholderIcon: Icons.queue_music_rounded),
                          title: Text(p.name, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
                          subtitle: Text('${p.songs.length} songs'),
                          trailing: p.songs.any((s) => s.videoId == song.videoId) ? Icon(Icons.check_rounded, color: scheme.primary) : null,
                          onTap: () {
                            final added = p.id == LibraryController.likedId ? !library.isLiked(song.videoId) : library.addSong(p.id, song);
                            if (p.id == LibraryController.likedId && added) library.toggleLike(song);
                            Navigator.pop(sheetCtx);
                            _toast(context, added ? 'Added to ${p.name}' : 'Already in ${p.name}');
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
