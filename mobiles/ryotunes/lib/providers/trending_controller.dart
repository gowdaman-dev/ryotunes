import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/youtube_music_service.dart';

/// South Indian languages the app surfaces music for.
const trendingLanguages = ['Tamil', 'Telugu', 'Malayalam', 'Kannada'];

enum FeedStatus { idle, loading, ready, failed }

class Feed {
  final FeedStatus status;
  final List<SongItem> songs;
  const Feed(this.status, [this.songs = const []]);
  bool get isLoading => status == FeedStatus.loading || status == FeedStatus.idle;
}

/// Discovery data. Every section is a keyed [Feed] with an explicit loading / ready / failed state,
/// so screens show skeletons while loading and a retry when the network fails (never fake data).
///
///  * `trending:<language>` – what's popular now (powers the New chart and Home teaser)
///  * `new:<language>`      – recent releases
///  * `artist:<name>`       – "more like this" from the user's listening
class TrendingController extends ChangeNotifier {
  final YouTubeMusicService _yt = YouTubeMusicService();
  final Map<String, Feed> _feeds = {};
  final Map<String, Future<List<SongItem>> Function()> _fetchers = {};
  String _language = trendingLanguages.first;

  String get language => _language;

  Feed feed(String key) => _feeds[key] ?? const Feed(FeedStatus.idle);
  Feed trending([String? lang]) => feed('trending:${lang ?? _language}');
  Feed fresh([String? lang]) => feed('new:${lang ?? _language}');
  Feed artist(String name) => feed('artist:$name');

  /// Back-compat for screens that just want the current language's songs.
  List<SongItem> songsFor(String lang) => trending(lang).songs;

  Future<void> select(String lang) async {
    if (lang == _language) return;
    _language = lang;
    notifyListeners();
    await Future.wait([loadTrending(lang), loadNew(lang)]);
  }

  Future<void> loadTrending(String lang, {bool force = false}) => _load(
        'trending:$lang',
        () => _mergeSearches(['$lang trending songs', '$lang top hits', '$lang popular songs ${DateTime.now().year}']),
        force: force,
      );

  Future<void> loadNew(String lang, {bool force = false}) => _load(
        'new:$lang',
        () => _mergeSearches(['$lang new songs ${DateTime.now().year}', '$lang latest release songs', '$lang new movie songs']),
        force: force,
      );

  Future<void> loadArtist(String name, {bool force = false}) => _load('artist:$name', () => _mergeSearches(['$name songs', '$name best']), force: force);

  Future<void> retry(String key) {
    final fetch = _fetchers[key];
    return fetch == null ? Future.value() : _load(key, fetch, force: true);
  }

  Future<void> _load(String key, Future<List<SongItem>> Function() fetch, {bool force = false}) async {
    _fetchers[key] = fetch;
    final current = _feeds[key];
    if (current != null && !force && (current.status == FeedStatus.loading || current.status == FeedStatus.ready)) return;
    _feeds[key] = Feed(FeedStatus.loading, current?.songs ?? const []);
    notifyListeners();
    final songs = await fetch();
    _feeds[key] = songs.isEmpty ? const Feed(FeedStatus.failed) : Feed(FeedStatus.ready, songs);
    notifyListeners();
  }

  /// Interleave several searches' results so the top of the list mixes them, dropping duplicates.
  Future<List<SongItem>> _mergeSearches(List<String> queries) async {
    final batches = await Future.wait(queries.map(_yt.search));
    final seen = <String>{};
    final merged = <SongItem>[];
    for (var i = 0; batches.any((b) => i < b.length); i++) {
      for (final b in batches) {
        if (i < b.length && seen.add(b[i].videoId)) merged.add(b[i]);
      }
    }
    return merged;
  }
}
