import 'package:flutter/material.dart';
import '../models/song.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'artwork.dart';
import 'song_menu.dart';

/// Borderless list row: artwork, title/artist, trailing "…" with an inset hairline divider.
class TrackRow extends StatelessWidget {
  final SongItem song;
  final int? index;
  final bool playing;
  final bool divider;
  final bool showArtwork;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  const TrackRow({super.key, required this.song, this.index, this.playing = false, this.divider = true, this.showArtwork = true, this.onTap, this.onMore});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: Sp.pagePad),
          child: Row(
            children: [
              if (index != null)
                SizedBox(width: 26, child: Text('${index! + 1}', style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface.withValues(alpha: 0.5)))),
              if (showArtwork) ...[Artwork(url: song.thumbnail, size: 52), const SizedBox(width: 14)],
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: divider ? Border(bottom: BorderSide(color: scheme.onSurface.withValues(alpha: 0.1))) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: RyFonts.ui(16, weight: FontWeight.w500, color: playing ? scheme.primary : scheme.onSurface)),
                            const SizedBox(height: 2),
                            Row(children: [
                              if (song.isUpload)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: scheme.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                                  child: Text('UPLOAD', style: RyFonts.ui(9, weight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: 0.6), letterSpacing: 0.4)),
                                ),
                              Expanded(
                                child: Text(song.artists, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.55))),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurface.withValues(alpha: 0.5)),
                        onPressed: onMore ?? () => showSongMenu(context, song),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
