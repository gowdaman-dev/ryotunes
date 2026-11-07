import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Apple-style section title: bold, with an optional chevron when it drills in.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final VoidCallback? onTap;
  const SectionHeader({super.key, required this.title, this.eyebrow, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.pagePad, 0, Sp.pagePad, Sp.md),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null)
                    Text(eyebrow!.toUpperCase(), style: RyFonts.ui(TypeScale.xs, weight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 0.6)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(title, style: RyFonts.ui(22, weight: FontWeight.w700, color: scheme.onSurface, letterSpacing: -0.4))),
                      if (onTap != null) Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.4), size: 26),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
