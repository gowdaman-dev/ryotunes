import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class ListenTogetherSheet extends StatelessWidget {
  const ListenTogetherSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listen Together', style: RyFonts.display(TypeScale.xl, color: scheme.onSurface)),
          const SizedBox(height: Sp.md),
          TextField(decoration: const InputDecoration(hintText: 'Server URL (ws://...)')),
          const SizedBox(height: Sp.sm),
          TextField(decoration: const InputDecoration(hintText: 'Your name')),
          const SizedBox(height: Sp.md),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () {}, child: const Text('Host room'))),
            const SizedBox(width: Sp.sm),
            Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Join room'))),
          ]),
          const SizedBox(height: Sp.md),
          Text('Invite code: RYO~...', style: RyFonts.mono(TypeScale.xs, color: scheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }
}