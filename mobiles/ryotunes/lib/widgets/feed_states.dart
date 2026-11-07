import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Shown in place of a section whose request failed.
class FeedError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const FeedError({super.key, required this.onRetry, this.message = "Couldn't load music. Check your connection."});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: scheme.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Radii.card)),
        child: Row(children: [
          Icon(Icons.wifi_off_rounded, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 14),
          Expanded(child: Text(message, style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.7)))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
