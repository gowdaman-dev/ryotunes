import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/library_controller.dart';
import '../../providers/lyrics_controller.dart';
import '../../providers/settings_controller.dart';
import '../../providers/sound_controller.dart';
import '../../providers/trending_controller.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/sound_sheet.dart';

/// Settings: every row here does something.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsController>();
    final trending = context.watch<TrendingController>();
    final sound = context.watch<SoundController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        title: Text('Settings', style: RyFonts.display(28, color: scheme.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _section(context, 'Music'),
          _tile(context, Icons.translate_rounded, 'Music language', trending.language, onTap: () => _chooseLanguage(context)),
          _tile(context, Icons.graphic_eq_rounded, 'Audio quality', settings.quality == AudioQuality.high ? 'High' : 'Data saver', onTap: () => _chooseQuality(context)),
          _tile(context, Icons.tune_rounded, 'Sound', sound.state.isFlat ? 'Flat' : (sound.activePreset?.name ?? 'Custom'), onTap: () => _openSound(context)),
          _section(context, 'Appearance'),
          _tile(context, Icons.brightness_6_outlined, 'Theme', _themeLabel(settings.themeMode), onTap: () => _chooseTheme(context)),
          _section(context, 'Home screen widgets'),
          _tile(context, Icons.widgets_outlined, 'Add Now Playing widget', 'Artwork and playback controls · 4×2', onTap: () => _pin(context, 'dev.ryoku.ryotunes.NowPlayingWidget')),
          _tile(context, Icons.view_stream_outlined, 'Add Compact widget', 'Slim player bar · 4×1', onTap: () => _pin(context, 'dev.ryoku.ryotunes.CompactWidget')),
          _section(context, 'Your data'),
          _tile(context, Icons.history_rounded, 'Clear recently played', 'Playlists and liked songs are kept', onTap: () => _confirmClearRecent(context)),
          _tile(context, Icons.cleaning_services_outlined, 'Clear cached images and lyrics', 'Frees space; they download again when needed', onTap: () => _clearCaches(context)),
          _section(context, 'About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => _tile(context, Icons.info_outline_rounded, 'Ryotunes', snap.hasData ? 'Version ${snap.data!.version} (${snap.data!.buildNumber})' : '', onTap: null),
          ),
          _tile(context, Icons.description_outlined, 'Open-source licenses', '', onTap: () => showLicensePage(context: context, applicationName: 'Ryotunes')),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode m) => switch (m) { ThemeMode.system => 'Match system', ThemeMode.light => 'Light', ThemeMode.dark => 'Dark' };

  Widget _section(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.pagePad, 26, Sp.pagePad, 6),
        child: Text(t.toUpperCase(), style: RyFonts.ui(TypeScale.xs, weight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 0.8)),
      );

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
      leading: Icon(icon),
      title: Text(title, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: scheme.onSurface)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface.withValues(alpha: 0.6))),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded, size: 22),
      onTap: onTap,
    );
  }

  /// A single-choice dialog; returns the picked value or null.
  Future<T?> _choose<T>(BuildContext context, String title, List<(T, String, String?)> options, T current) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final o in options)
            ListTile(
              title: Text(o.$2),
              subtitle: o.$3 == null ? null : Text(o.$3!),
              trailing: o.$1 == current ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary) : null,
              onTap: () => Navigator.pop(ctx, o.$1),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final trending = context.read<TrendingController>();
    final picked = await _choose<String>(context, 'Music language', [for (final l in trendingLanguages) (l, l, null)], trending.language);
    if (picked != null) trending.select(picked);
  }

  Future<void> _chooseQuality(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final picked = await _choose<AudioQuality>(context, 'Audio quality', const [
      (AudioQuality.high, 'High', 'Best available sound'),
      (AudioQuality.dataSaver, 'Data saver', 'Smaller streams for mobile data'),
    ], settings.quality);
    if (picked != null) {
      await settings.setQuality(picked);
      if (context.mounted) _toast(context, 'Applies to songs you start from now on');
    }
  }

  Future<void> _chooseTheme(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final picked = await _choose<ThemeMode>(context, 'Theme', const [
      (ThemeMode.system, 'Match system', null),
      (ThemeMode.dark, 'Dark', null),
      (ThemeMode.light, 'Light', null),
    ], settings.themeMode);
    if (picked != null) settings.setThemeMode(picked);
  }

  void _openSound(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
      builder: (_) => const SoundSheet(),
    );
  }

  Future<void> _confirmClearRecent(BuildContext context) async {
    final library = context.read<LibraryController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear recently played?'),
        content: const Text('Your playlists and liked songs stay. Home will learn your taste again from scratch.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      library.clearRecent();
      if (context.mounted) _toast(context, 'Recently played cleared');
    }
  }

  Future<void> _clearCaches(BuildContext context) async {
    final lyrics = context.read<LyricsController>();
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    lyrics.clearCache();
    if (context.mounted) _toast(context, 'Cache cleared');
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

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
