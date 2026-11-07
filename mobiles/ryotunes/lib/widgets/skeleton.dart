import 'package:flutter/material.dart';
import '../theme/spacing.dart';

/// Drives one shared shimmer sweep for every [SkeletonBox] below it, so a whole screen pulses in sync.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF1C1C1E) : const Color(0xFFE9E9EE);
    final glow = dark ? const Color(0xFF3A3A3E) : const Color(0xFFF7F7FA);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1.6 + 3.2 * t, -0.3),
            end: Alignment(-0.6 + 3.2 * t, 0.3),
            colors: [base, glow, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// A grey rounded block; wrap a group of these in [Shimmer].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final bool circle;
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8, this.circle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.white, shape: circle ? BoxShape.circle : BoxShape.rectangle, borderRadius: circle ? null : BorderRadius.circular(radius)),
    );
  }
}

/// Placeholder for a [TrackRow].
class SkeletonTrackRow extends StatelessWidget {
  final double titleWidth;
  const SkeletonTrackRow({super.key, this.titleWidth = 180});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.pagePad, 10, Sp.pagePad, 10),
      child: Row(children: [
        const SkeletonBox(width: 52, height: 52, radius: 6),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: titleWidth, height: 14),
          const SizedBox(height: 8),
          SkeletonBox(width: titleWidth * 0.6, height: 12),
        ]),
      ]),
    );
  }
}

/// A shimmering stack of track rows.
class SkeletonTrackList extends StatelessWidget {
  final int count;
  const SkeletonTrackList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(children: [for (var i = 0; i < count; i++) SkeletonTrackRow(titleWidth: 150.0 + (i * 37 % 90))]),
    );
  }
}

/// Placeholder for a horizontal row of [SquareCard]s.
class SkeletonCardRow extends StatelessWidget {
  final double size;
  const SkeletonCardRow({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: size + 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(width: size, height: size, radius: Radii.card),
            const SizedBox(height: 10),
            SkeletonBox(width: size * 0.8, height: 13),
            const SizedBox(height: 6),
            SkeletonBox(width: size * 0.5, height: 11),
          ]),
        ),
      ),
    );
  }
}

/// Placeholder for a [HeroCard] carousel.
class SkeletonHero extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonHero({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBox(width: 120, height: 11),
          const SizedBox(height: 8),
          SkeletonBox(width: width * 0.7, height: 20),
          const SizedBox(height: 12),
          SkeletonBox(width: width, height: height, radius: Radii.hero),
        ]),
      ),
    );
  }
}
