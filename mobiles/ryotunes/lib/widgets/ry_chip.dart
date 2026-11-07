import 'package:flutter/material.dart';
import '../theme/typography.dart';

/// Filled pill; the selected one inverts to the accent colour.
class RyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const RyChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: RyFonts.ui(14, weight: FontWeight.w600, color: selected ? Colors.white : scheme.onSurface)),
      ),
    );
  }
}
