import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/catalog.dart';
import '../../models/song.dart';
import '../../providers/player_controller.dart';
import '../../providers/trending_controller.dart';
import '../../services/youtube_music_service.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/large_title_bar.dart';
import '../../widgets/media_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/track_row.dart';

/// Search: official songs first, then regular uploads for tracks that have no official audio.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _svc = YouTubeMusicService();
  Timer? _debounce;
  String _query = '';
  List<SongItem> _songs = [];
  List<SongItem> _uploads = [];
  List<CatalogItem> _artists = [];
  List<CatalogItem> _albums = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() { _query = ''; _songs = []; _uploads = []; _artists = []; _albums = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _run(q));
  }

  Future<void> _run(String q) async {
    final results = await Future.wait<Object>([_svc.search(q), _svc.searchUploads(q), _svc.searchArtists(q), _svc.searchAlbums(q)]);
    if (!mounted || _ctrl.text.trim() != q) return;
    final songs = results[0] as List<SongItem>;
    final uploads = results[1] as List<SongItem>;
    final officialIds = songs.map((s) => s.videoId).toSet();
    setState(() {
      _query = q;
      _songs = songs;
      _uploads = uploads.where((s) => !officialIds.contains(s.videoId)).toList();
      _artists = (results[2] as List<CatalogItem>).take(8).toList();
      _albums = (results[3] as List<CatalogItem>).take(8).toList();
      _loading = false;
    });
  }

  void _play(List<SongItem> list, int i) {
    context.read<PlayerController>().setQueue(list, start: i);
    context.push('/now-playing');
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.pagePad, 20, Sp.pagePad, 8),
        child: Text(text, style: RyFonts.ui(22, weight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
      );

  Widget _shelf(List<CatalogItem> items, {bool round = false}) => SizedBox(
        height: round ? 170 : 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Sp.pagePad),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) => SquareCard(
            size: round ? 110 : 140,
            round: round,
            title: items[i].title,
            subtitle: items[i].subtitle,
            thumbnail: items[i].thumbnail,
            onTap: () => context.push(round ? '/artist/${items[i].id}' : '/album/${items[i].id}'),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final player = context.watch<PlayerController>();
    final suggestions = [...trendingLanguages.map((l) => '$l songs'), 'Anirudh hits', 'AR Rahman', 'Sid Sriram', 'Ilaiyaraaja'];
    final hasResults = _songs.isNotEmpty || _uploads.isNotEmpty || _artists.isNotEmpty || _albums.isNotEmpty;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverToBoxAdapter(child: LargeTitleBar(title: 'Search')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Sp.pagePad, 0, Sp.pagePad, 4),
            child: TextField(
              controller: _ctrl,
              style: RyFonts.ui(17, color: scheme.onSurface),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Songs, artists, movies',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _ctrl.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _ctrl.clear(); _onChanged(''); }),
              ),
              onChanged: _onChanged,
            ),
          ),
        ),
        if (_loading && !hasResults) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 12), child: SkeletonTrackList(count: 7))),
        if (_query.isEmpty && !_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.pagePad, 24, Sp.pagePad, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(label: Text(s), onPressed: () { _ctrl.text = s; _onChanged(s); }),
                ],
              ),
            ),
          ),
        if (_artists.isNotEmpty) SliverToBoxAdapter(child: _header('Artists')),
        if (_artists.isNotEmpty) SliverToBoxAdapter(child: _shelf(_artists, round: true)),
        if (_albums.isNotEmpty) SliverToBoxAdapter(child: _header('Albums')),
        if (_albums.isNotEmpty) SliverToBoxAdapter(child: _shelf(_albums)),
        if (_songs.isNotEmpty) SliverToBoxAdapter(child: _header('Songs')),
        SliverList.builder(
          itemCount: _songs.length,
          itemBuilder: (_, i) => TrackRow(song: _songs[i], playing: player.now?.videoId == _songs[i].videoId, onTap: () => _play(_songs, i)),
        ),
        if (_uploads.isNotEmpty) SliverToBoxAdapter(child: _header('More from YouTube')),
        if (_uploads.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.pagePad, 0, Sp.pagePad, 8),
              child: Text('Uploads and covers with no official audio track. Playback is audio only.', style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface.withValues(alpha: 0.5))),
            ),
          ),
        SliverList.builder(
          itemCount: _uploads.length,
          itemBuilder: (_, i) => TrackRow(song: _uploads[i], playing: player.now?.videoId == _uploads[i].videoId, onTap: () => _play(_uploads, i)),
        ),
        if (_query.isNotEmpty && !_loading && !hasResults)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('No results for "$_query"', style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.5)))))),
        const SliverToBoxAdapter(child: SizedBox(height: kShellBottomInset)),
      ],
    );
  }
}
