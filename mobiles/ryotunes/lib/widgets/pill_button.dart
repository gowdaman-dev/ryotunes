import 'package:flutter/material.dart';
import '../theme/typography.dart';

/// Wide tinted button used for Play / Shuffle on playlist, artist and album pages.
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const PillButton({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: scheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 6),
            Text(label, style: RyFonts.ui(17, weight: FontWeight.w600, color: scheme.primary)),
          ]),
        ),
      ),
    );
  }
}
