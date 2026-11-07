import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: RyFonts.display(TypeScale.xl, color: scheme.onSurface))),
      body: ListView(
        children: [
          _section(context, 'Home screen widgets'),
          _tile(context, Icons.widgets_outlined, 'Add Now Playing widget', 'Artwork and playback controls · 4×2', onTap: () => _pin(context, 'dev.ryoku.ryotunes.NowPlayingWidget')),
          _tile(context, Icons.view_stream_outlined, 'Add Compact widget', 'Slim player bar · 4×1', onTap: () => _pin(context, 'dev.ryoku.ryotunes.CompactWidget')),
          _section(context, 'Appearance'),
          _tile(context, Icons.palette_outlined, 'Theme', 'Follow system (Ryotunes)'),
          _tile(context, Icons.brush_outlined, 'Skin', 'system'),
          _tile(context, Icons.language, 'Language / Region', 'Tamil (ta-IN) — first preference'),
          _tile(context, Icons.tune, 'Decor', 'Skin default'),
          _tile(context, Icons.text_fields, 'Interface scale', '100%'),
          _tile(context, Icons.history, 'Watch history', 'On'),
          _tile(context, Icons.battery_saver_outlined, 'Low resource mode', 'Off'),
          _section(context, 'Playback'),
          _tile(context, Icons.speed, 'Audio quality', 'Auto'),
          _tile(context, Icons.play_circle_outline, 'Autoplay', 'On'),
          _tile(context, Icons.repeat, 'Prevent duplicates', 'Off'),
          _tile(context, Icons.lyrics_outlined, 'Word-by-word lyrics', 'On'),
          _tile(context, Icons.translate, 'Romanized lyrics', 'On'),
          _tile(context, Icons.equalizer, 'Sound (tempo/pitch/FX)', 'Open'),
          _section(context, 'Providers'),
          _tile(context, Icons.play_circle_outline, 'YouTube Music', 'Not signed in'),
          _tile(context, Icons.music_note, 'Spotify', 'Not signed in'),
          _tile(context, Icons.cloud_outlined, 'SoundCloud', 'Not signed in'),
          _tile(context, Icons.waves, 'TIDAL', 'Not signed in'),
          _section(context, 'Data & storage'),
          _tile(context, Icons.wifi, 'Proxy', 'None (restart to apply)'),
          _tile(context, Icons.cleaning_services_outlined, 'Force clear caches', ''),
          _section(context, 'Account'),
          _tile(context, Icons.person_outline, 'Channel switcher', 'Default'),
          _section(context, 'Local music'),
          _tile(context, Icons.folder, 'Watched folders', '0 folders'),
          _section(context, 'Playlists'),
          _tile(context, Icons.file_upload_outlined, 'Import playlist', ''),
          _section(context, 'About'),
          _tile(context, Icons.info_outline, 'Ryotunes', 'v1.0.0'),
          _tile(context, Icons.system_update, 'Check for updates', ''),
          _tile(context, Icons.description_outlined, 'Release notes', ''),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.xs),
    child: Text(t.toUpperCase(), style: RyFonts.mono(TypeScale.micro, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.4)),
  );

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) => ListTile(
    leading: Icon(icon),
    title: Text(title, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
    subtitle: subtitle.isEmpty ? null : Text(subtitle, style: RyFonts.ui(TypeScale.xs, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
    trailing: const Icon(Icons.chevron_right, size: 18),
    onTap: onTap ?? () {},
  );

  /// Asks Android to pin [name] to the home screen (the system shows its own confirmation).
  Future<void> _pin(BuildContext context, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) {
      messenger.showSnackBar(const SnackBar(content: Text('Your launcher cannot add widgets from here. Long-press the home screen and pick Ryotunes under Widgets.')));
      return;
    }
    await HomeWidget.requestPinWidget(qualifiedAndroidName: name);
  }
}