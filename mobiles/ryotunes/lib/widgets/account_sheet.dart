import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';

class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final providers = [
      ('YouTube Music', ProviderColors.youtube, Icons.play_circle_outline),
      ('Spotify', ProviderColors.spotify, Icons.music_note),
      ('SoundCloud', ProviderColors.soundcloud, Icons.cloud_outlined),
      ('TIDAL', ProviderColors.tidal, Icons.waves),
    ];
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/brand/logo.png', width: 48, height: 48)),
            const SizedBox(width: 14),
            Text('Ryotunes', style: RyFonts.display(28, color: scheme.onSurface)),
          ]),
          const SizedBox(height: Sp.md),
          for (final p in providers) ...[
            ListTile(
              leading: Icon(p.$3, color: p.$2),
              title: Text(p.$1, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
              subtitle: Text('Not signed in', style: RyFonts.ui(TypeScale.xs, color: scheme.onSurface.withValues(alpha: 0.6))),
              trailing: FilledButton.tonal(onPressed: () {}, child: const Text('Sign in')),
            ),
            const Divider(height: 1),
          ],
          for (final e in [('Settings', Icons.settings_outlined, '/settings')])
            ListTile(
              leading: Icon(e.$2),
              title: Text(e.$1, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push(e.$3);
              },
            ),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }
}