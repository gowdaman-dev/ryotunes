import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/lyrics.dart';
import '../providers/lyrics_controller.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'skeleton.dart';

/// Lyrics panel: synced lines follow playback (tap to seek), plain lyrics scroll, and the empty
/// states say so explicitly instead of showing filler text.
class LyricsView extends StatefulWidget {
  final LyricsStatus status;
  final Lyrics? lyrics;
  final Duration position;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onRetry;
  const LyricsView({super.key, required this.status, required this.lyrics, required this.position, required this.onSeek, required this.onRetry});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _keys = <int, GlobalKey>{};
  final _scroll = ScrollController();
  int _lastActive = -2;
  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void didUpdateWidget(covariant LyricsView old) {
    super.didUpdateWidget(old);
    if (old.lyrics != widget.lyrics) {
      _keys.clear();
      _lastActive = -2;
    }
    final active = widget.lyrics?.activeIndex(widget.position) ?? -1;
    if (active != _lastActive) {
      _lastActive = active;
      final userIsBrowsing = DateTime.now().difference(_userScrolledAt) < const Duration(seconds: 3);
      if (active >= 0 && !userIsBrowsing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _keys[active]?.currentContext;
          if (ctx != null && mounted) {
            Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.status) {
      case LyricsStatus.idle:
      case LyricsStatus.loading:
        return const _LyricsSkeleton();
      case LyricsStatus.unavailable:
        return _Message(icon: Icons.lyrics_outlined, title: 'Lyrics not available', body: "We couldn't find lyrics for this song yet.");
      case LyricsStatus.failed:
        return _Message(icon: Icons.wifi_off_rounded, title: "Couldn't load lyrics", body: 'Check your connection and try again.', onRetry: widget.onRetry);
      case LyricsStatus.ready:
        return _buildLines();
    }
  }

  Widget _buildLines() {
    final lyrics = widget.lyrics!;
    final active = lyrics.activeIndex(widget.position);
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.1, 0.88, 1],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          _userScrolledAt = DateTime.now();
          return false;
        },
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(Sp.pagePad, 70, Sp.pagePad, 160),
          itemCount: lyrics.lines.length,
          itemBuilder: (_, i) {
            final line = lyrics.lines[i];
            if (line.text.isEmpty) return const SizedBox(height: 28);
            final key = _keys.putIfAbsent(i, GlobalKey.new);
            final distance = lyrics.synced ? (i - active).abs() : 0;
            final isActive = lyrics.synced && i == active;
            final blur = !lyrics.synced || isActive || distance > 4 ? 0.0 : distance * 1.1;
            final opacity = !lyrics.synced ? 0.88 : (isActive ? 1.0 : (distance <= 4 ? 0.42 : 0.28));
            Widget text = AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: RyFonts.ui(30, weight: FontWeight.w800, letterSpacing: -0.5, height: 1.2, color: Colors.white.withValues(alpha: opacity)),
              child: Text(line.text),
            );
            if (blur > 0) text = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: text);
            return GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: lyrics.synced ? () => widget.onSeek(line.time) : null,
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: text),
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.title, required this.body, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 54, color: Colors.white.withValues(alpha: 0.55)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: RyFonts.ui(22, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: RyFonts.ui(TypeScale.md, color: Colors.white.withValues(alpha: 0.6), height: 1.35)),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
          ],
        ]),
      ),
    );
  }
}

class _LyricsSkeleton extends StatelessWidget {
  const _LyricsSkeleton();
  @override
  Widget build(BuildContext context) {
    const widths = [0.8, 0.6, 0.9, 0.5, 0.75, 0.65];
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.pagePad, 60, Sp.pagePad, 0),
        child: LayoutBuilder(
          builder: (context, c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in widths) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: SkeletonBox(width: c.maxWidth * w, height: 26, radius: 8)),
            ],
          ),
        ),
      ),
    );
  }
}
