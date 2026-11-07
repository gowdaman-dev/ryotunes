import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/spacing.dart';
import 'skeleton.dart';

/// Network image that crops the black letterbox bars YouTube bakes into 4:3 video thumbnails.
class RemoteArt extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final IconData placeholderIcon;
  const RemoteArt({super.key, required this.url, required this.width, required this.height, this.placeholderIcon = Icons.music_note_rounded});

  static bool _letterboxed(String u) => u.contains('ytimg.com');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blank = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(placeholderIcon, size: width * 0.3, color: scheme.onSurface.withValues(alpha: 0.3)),
    );
    final u = url;
    if (u == null || u.isEmpty) return blank;
    Widget image = CachedNetworkImage(
      imageUrl: u,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: (width * 3).toInt(),
      fadeInDuration: const Duration(milliseconds: 280),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (_, _) => Shimmer(child: SkeletonBox(width: width, height: height, radius: 0)),
      errorWidget: (_, _, _) => blank,
    );
    if (_letterboxed(u)) image = Transform.scale(scale: 1.34, child: image);
    return SizedBox(width: width, height: height, child: ClipRect(child: image));
  }
}

/// Rounded square (or circular) artwork with placeholder.
class Artwork extends StatelessWidget {
  final String? url;
  final double size;
  final bool round;
  final IconData placeholderIcon;
  const Artwork({super.key, this.url, this.size = 48, this.round = false, this.placeholderIcon = Icons.music_note});

  @override
  Widget build(BuildContext context) {
    final r = round ? size / 2 : Radii.control - 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: RemoteArt(url: url, width: size, height: size, placeholderIcon: placeholderIcon),
    );
  }
}
