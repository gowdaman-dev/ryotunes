import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'artwork.dart';

class PageHero extends StatelessWidget {
  final String? thumbnail;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool roundArt;
  final double artSize;
  const PageHero({super.key, this.thumbnail, required this.eyebrow, required this.title, this.subtitle, this.actions = const [], this.roundArt = false, this.artSize = 168});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Artwork(url: thumbnail, size: artSize, round: roundArt),
          const SizedBox(width: Sp.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: RyFonts.mono(TypeScale.micro, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.4)),
                const SizedBox(height: Sp.xs),
                Text(title, style: RyFonts.display(TypeScale.title, color: scheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: Sp.xs),
                  Text(subtitle!, style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface.withValues(alpha: 0.6))),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: Sp.md),
                  Wrap(spacing: Sp.sm, runSpacing: Sp.xs, children: actions),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}