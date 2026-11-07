import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/catalog_controller.dart';
import 'providers/library_controller.dart';
import 'providers/lyrics_controller.dart';
import 'providers/player_controller.dart';
import 'providers/settings_controller.dart';
import 'providers/sound_controller.dart';
import 'providers/trending_controller.dart';
import 'router.dart';
import 'services/audio_handler.dart';
import 'services/widget_sync.dart';
import 'theme/ryotunes_theme.dart';

class RyotunesApp extends StatelessWidget {
  const RyotunesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryController()..load()),
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
        ChangeNotifierProvider(create: (_) => LyricsController()),
        ChangeNotifierProvider(create: (_) => SoundController(handler: audioHandler)..load()),
        ChangeNotifierProvider(create: (_) => CatalogController()),
        ChangeNotifierProvider(create: (ctx) {
          final player = PlayerController(onPlay: ctx.read<LibraryController>().addRecent);
          WidgetSync(player); // keeps the home-screen widgets in step with playback
          return player;
        }),
        ChangeNotifierProvider(create: (_) => TrendingController()..init()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp.router(
          title: 'Ryotunes',
          theme: RyotunesTheme.light(),
          darkTheme: RyotunesTheme.dark(),
          themeMode: settings.themeMode,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}