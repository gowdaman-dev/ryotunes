import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/song.dart';
import '../../providers/lyrics_controller.dart';
import '../../providers/player_controller.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../util/artwork_color.dart';
import '../../util/navigation.dart';
import '../../widgets/artwork.dart';
import '../../widgets/lyrics_view.dart';
import '../../widgets/queue_sheet.dart';
import '../../widgets/sound_sheet.dart';
import '../../widgets/song_menu.dart';

/// Full-screen player: artwork-tinted blurred backdrop, lyrics focus, thin scrubber, big transport.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});
  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  String? _tintFor;
  bool _showLyrics = true;
  String? _lyricsFor;
  Color _tint = const Color(0xFF3A3A3C);

  void _updateTint(String? url) {
    if (url == _tintFor) return;
    _tintFor = url;
    artworkColor(url).then((c) {
      if (c != null && mounted && _tintFor == url) setState(() => _tint = c);
    });
  }

  void _ensureLyrics(SongItem song) {
    if (_lyricsFor == song.videoId) return;
    _lyricsFor = song.videoId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LyricsController>().load(song);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerController>();
    if (!p.hasNow) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: Text('Nothing playing')),
      );
    }
    final song = p.now!;
    _updateTint(song.thumbnail);
    _ensureLyrics(song);
    final lyricsCtl = context.watch<LyricsController>();
    const white = Colors.white;
    final remaining = (p.duration - p.position).clamp(0, double.infinity).toDouble();
    final progress = p.duration > 0 ? (p.position / p.duration).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_tint, Color.lerp(_tint, Colors.black, 0.7)!, const Color(0xFF111111)],
              ),
            ),
          ),
          Positioned(
            left: -80, top: 220,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, color: _tint.withValues(alpha: 0.55))),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onVerticalDragEnd: (d) { if ((d.primaryVelocity ?? 0) > 300) context.pop(); },
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.pagePad, 22, Sp.pagePad, 0),
                    child: Row(
                      children: [
                        Hero(tag: 'art-${song.videoId}', child: Artwork(url: song.thumbnail, size: 68)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(20, weight: FontWeight.w700, color: white)),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: song.artistRefs.isEmpty ? null : () => openArtistOf(context, song, closePlayer: true),
                                child: Row(children: [
                                  Flexible(child: Text(song.artists, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(TypeScale.lg, color: white.withValues(alpha: 0.6)))),
                                  if (song.artistRefs.isNotEmpty) Icon(Icons.chevron_right_rounded, size: 20, color: white.withValues(alpha: 0.5)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        _RoundButton(
                          icon: Icons.more_horiz_rounded,
                          onTap: () => showSongMenu(context, song, fromPlayer: true, extra: [
                            (
                              Icons.graphic_eq_rounded,
                              'Sound',
                              () => showModalBottomSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    isScrollControlled: true,
                                    backgroundColor: const Color(0xFF1C1C1E),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
                                    builder: (_) => const SoundSheet(),
                                  ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  if (p.error != PlaybackError.none)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Sp.pagePad, 14, Sp.pagePad, 0),
                      child: _ErrorBanner(
                        message: p.error == PlaybackError.offline ? "You're offline. Reconnect to keep listening." : "Can't play this song right now.",
                        onRetry: p.retry,
                        onSkip: p.hasNext ? p.next : null,
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showLyrics
                          ? LyricsView(
                              key: const ValueKey('lyrics'),
                              status: lyricsCtl.videoId == song.videoId ? lyricsCtl.status : LyricsStatus.loading,
                              lyrics: lyricsCtl.videoId == song.videoId ? lyricsCtl.lyrics : null,
                              position: Duration(milliseconds: (p.position * 1000).round()),
                              onSeek: (d) => p.seek(d.inMilliseconds / 1000),
                              onRetry: () => context.read<LyricsController>().load(song, force: true),
                            )
                          : _BigArtwork(key: const ValueKey('art'), song: song, playing: !p.paused),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.pagePad, 0, Sp.pagePad, 0),
                    child: Column(
                      children: [
                        _Scrubber(value: progress, onChanged: (v) => p.seek(v * p.duration)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(p.position), style: RyFonts.mono(TypeScale.sm, color: white.withValues(alpha: 0.55))),
                            Text('-${_fmt(remaining)}', style: RyFonts.mono(TypeScale.sm, color: white.withValues(alpha: 0.55))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(iconSize: 48, color: white, icon: const Icon(Icons.fast_rewind_rounded), onPressed: p.prev),
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: p.loading
                              ? const Center(child: SizedBox(width: 38, height: 38, child: CircularProgressIndicator(strokeWidth: 3.5, color: Colors.white)))
                              : IconButton(iconSize: 76, color: white, icon: Icon(p.paused ? Icons.play_arrow_rounded : Icons.pause_rounded), onPressed: p.togglePause),
                        ),
                        IconButton(iconSize: 48, color: white, icon: const Icon(Icons.fast_forward_rounded), onPressed: p.next),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad + 4),
                    child: Row(
                      children: [
                        Icon(Icons.volume_mute_rounded, color: white.withValues(alpha: 0.55), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: _Scrubber(value: p.volume, onChanged: p.setVolume, thickness: 6)),
                        const SizedBox(width: 10),
                        Icon(Icons.volume_up_rounded, color: white.withValues(alpha: 0.55), size: 20),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 16, 36, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BottomToggle(icon: Icons.format_quote_rounded, active: _showLyrics, tooltip: _showLyrics ? 'Hide lyrics' : 'Show lyrics', onTap: () => setState(() => _showLyrics = !_showLyrics)),
                        _BottomToggle(
                          icon: p.repeat == LoopSetting.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                          active: p.repeat != LoopSetting.off,
                          tooltip: 'Repeat: ${p.repeat.name}',
                          onTap: p.cycleRepeat,
                        ),
                        _BottomToggle(icon: Icons.shuffle_rounded, active: p.shuffle, tooltip: p.shuffle ? 'Shuffle on' : 'Shuffle off', onTap: p.toggleShuffle),
                        _BottomToggle(icon: Icons.queue_music_rounded, active: false, tooltip: 'Queue', onTap: () => showQueueSheet(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).toInt().toString().padLeft(2, '0');
    return '$m:$sec';
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16)),
          child: Icon(icon, color: Colors.white),
        ),
      );
}

class _BottomToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;
  const _BottomToggle({required this.icon, required this.active, required this.onTap, required this.tooltip});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, color: active ? Colors.white.withValues(alpha: 0.25) : Colors.transparent),
          child: Icon(icon, color: Colors.white.withValues(alpha: active ? 1 : 0.6), size: 26),
        ),
      ));
}

/// Thin pill scrubber (no thumb) like Apple Music's progress bar.
class _Scrubber extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double thickness;
  const _Scrubber({required this.value, required this.onChanged, this.thickness = 8});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      void set(double dx) => onChanged((dx / c.maxWidth).clamp(0.0, 1.0));
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => set(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
        child: SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(thickness),
              child: Stack(
                children: [
                  Container(height: thickness, width: c.maxWidth, color: Colors.white.withValues(alpha: 0.25)),
                  Container(height: thickness, width: c.maxWidth * value.clamp(0.0, 1.0), color: Colors.white.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}


/// Large artwork shown when lyrics are hidden; shrinks while paused like Apple Music.
class _BigArtwork extends StatelessWidget {
  final SongItem song;
  final bool playing;
  const _BigArtwork({super.key, required this.song, required this.playing});

  @override
  Widget build(BuildContext context) {
    final side = (MediaQuery.of(context).size.width - Sp.pagePad * 2).clamp(200.0, 420.0);
    return Center(
      child: AnimatedScale(
        scale: playing ? 1 : 0.86,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.hero),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(Radii.hero), child: RemoteArt(url: song.thumbnail, width: side, height: side)),
        ),
      ),
    );
  }
}


class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSkip;
  const _ErrorBanner({required this.message, required this.onRetry, this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: RyFonts.ui(TypeScale.md, color: Colors.white))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
        if (onSkip != null) TextButton(onPressed: onSkip, child: const Text('Skip')),
      ]),
    );
  }
}
