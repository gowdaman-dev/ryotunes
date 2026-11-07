import 'dart:ui';
import 'package:flutter/material.dart';

/// Frosted surface used by the floating tab bar, mini-player and sheets.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  const Glass({super.key, required this.child, this.radius = 32, this.blur = 28, this.padding, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? const Color(0xFF2C2C2E).withValues(alpha: 0.62) : Colors.white.withValues(alpha: 0.66);
    final edge = dark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.7);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.4 : 0.12), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: edge, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
