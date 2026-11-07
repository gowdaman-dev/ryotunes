import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Pushes [path] on top of the tab shell. When opened from the full-screen player ([closePlayer])
/// the player is closed first, otherwise the new page would open underneath it, out of sight (and
/// pushing a shell page over a root page duplicates a Navigator page key). The push waits for the
/// close animation to finish.
Future<void> _open(BuildContext context, String path, {required bool closePlayer}) async {
  final router = GoRouter.of(context);
  if (closePlayer && router.canPop()) {
    router.pop();
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }
  router.push(path);
}

void openArtist(BuildContext context, String artistId, {bool closePlayer = false}) => _open(context, '/artist/$artistId', closePlayer: closePlayer);
void openAlbum(BuildContext context, String albumId, {bool closePlayer = false}) => _open(context, '/album/$albumId', closePlayer: closePlayer);

/// Go to a song's artist; when it credits several, let the user pick which one.
Future<void> openArtistOf(BuildContext context, SongItem song, {bool closePlayer = false}) async {
  final refs = song.artistRefs;
  if (refs.isEmpty) return;
  if (refs.length == 1) return openArtist(context, refs.first.id, closePlayer: closePlayer);
  final picked = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.pagePad, 20, Sp.pagePad, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Go to Artist', style: RyFonts.ui(22, weight: FontWeight.w700, color: scheme.onSurface))),
          ),
          for (final a in refs)
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(a.name, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(ctx, a.id),
            ),
          const SizedBox(height: 8),
        ]),
      );
    },
  );
  if (picked != null && context.mounted) openArtist(context, picked, closePlayer: closePlayer);
}
