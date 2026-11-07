import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/library/library_screen.dart';
import 'features/now_playing/now_playing_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/album/album_screen.dart';
import 'features/artist/artist_screen.dart';
import 'features/playlist/playlist_screen.dart';
import 'features/radio/radio_screen.dart';
import 'features/new/new_screen.dart';
import 'widgets/floating_nav.dart';
import 'widgets/mini_player.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/new', builder: (_, __) => const NewScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
        GoRoute(path: '/radio', builder: (_, __) => const RadioScreen()),
        GoRoute(path: '/artist/:id', builder: (_, st) => ArtistScreen(id: st.pathParameters['id']!)),
        GoRoute(path: '/album/:id', builder: (_, st) => AlbumScreen(id: st.pathParameters['id']!)),
        GoRoute(path: '/playlist/:id', builder: (_, st) => PlaylistScreen(id: st.pathParameters['id']!)),
      ],
    ),
    GoRoute(
      path: '/now-playing',
      pageBuilder: (ctx, st) => _fadePage(ctx, st, const NowPlayingScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (ctx, st) => _fadePage(ctx, st, const SettingsScreen()),
    ),
  ],
);

/// Tab shell: content runs edge-to-edge beneath a floating mini-player and glass tab bar.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayer(),
                  const SizedBox(height: 8),
                  FloatingNav(location: loc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

CustomTransitionPage<void> _fadePage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(fade);
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
  );
}