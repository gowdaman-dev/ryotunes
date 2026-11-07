import 'package:flutter/material.dart';
import 'artwork.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Square artwork tile with title/subtitle underneath (Recently Played, albums).
class SquareCard extends StatelessWidget {
  final String? thumbnail;
  final String title;
  final String? subtitle;
  final double size;
  final bool round;
  final VoidCallback? onTap;
  const SquareCard({super.key, this.thumbnail, required this.title, this.subtitle, this.size = 150, this.round = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: round ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(round ? size / 2 : Radii.card),
              child: RemoteArt(url: thumbnail, width: size, height: size),
            ),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: round ? TextAlign.center : TextAlign.start,
                style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
            if (subtitle != null)
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: round ? TextAlign.center : TextAlign.start,
                  style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}

/// Large feature card: full-bleed artwork, scrim, eyebrow + title + caption (New tab, Top Picks).
class HeroCard extends StatelessWidget {
  final String? thumbnail;
  final String eyebrow;
  final String title;
  final String? caption;
  final double width;
  final double height;
  final VoidCallback? onTap;
  const HeroCard({super.key, this.thumbnail, required this.eyebrow, required this.title, this.caption, required this.width, this.height = 300, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow.toUpperCase(), style: RyFonts.ui(TypeScale.xs, weight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyFonts.ui(22, weight: FontWeight.w600, color: scheme.onSurface, letterSpacing: -0.3)),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.hero),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.hero),
                child: SizedBox(
                  height: height,
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RemoteArt(url: thumbnail, width: width, height: height),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC000000)]),
                        ),
                      ),
                      if (caption != null)
                        Positioned(
                          left: 16, right: 16, bottom: 16,
                          child: Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
