import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_controller.dart';
import '../theme/typography.dart';
import 'artwork.dart';
import 'glass.dart';

/// Floating glass now-playing pill that sits above the tab bar.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerController>();
    final scheme = Theme.of(context).colorScheme;
    final song = p.now;
    final progress = p.duration > 0 ? (p.position / p.duration).clamp(0.0, 1.0) : 0.0;
    return GestureDetector(
      onTap: p.hasNow ? () => context.push('/now-playing') : null,
      child: Glass(
        radius: 30,
        height: 60,
        padding: const EdgeInsets.fromLTRB(8, 0, 6, 0),
        child: Stack(
          children: [
            Row(
              children: [
                Artwork(url: song?.thumbnail, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song?.title ?? 'Not Playing', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: RyFonts.ui(TypeScale.md, weight: FontWeight.w600, color: scheme.onSurface)),
                      if (song != null)
                        Text(
                          p.error == PlaybackError.none ? song.artists : (p.error == PlaybackError.offline ? "Offline · tap play to retry" : "Can't play · tap play to retry"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RyFonts.ui(TypeScale.xs, color: p.error == PlaybackError.none ? scheme.onSurface.withValues(alpha: 0.6) : scheme.error),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 30,
                  icon: Icon(p.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  onPressed: p.hasNow ? p.togglePause : null,
                ),
                IconButton(iconSize: 30, icon: const Icon(Icons.fast_forward_rounded), onPressed: p.hasNow ? p.next : null),
              ],
            ),
            if (p.hasNow)
              Positioned(
                left: 8, right: 8, bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: progress, minHeight: 2, color: scheme.primary, backgroundColor: Colors.transparent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
