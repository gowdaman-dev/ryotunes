import 'package:flutter/foundation.dart';
import '../models/catalog.dart';
import '../models/song.dart';
import '../services/youtube_music_service.dart';
import 'trending_controller.dart' show FeedStatus;

/// One page's load state: loading until it resolves, then ready or failed.
class Entry<T> {
  final FeedStatus status;
  final T? data;
  const Entry(this.status, [this.data]);
  bool get isLoading => status == FeedStatus.loading || status == FeedStatus.idle;
}

/// Artist and album pages, cached for the session so revisiting (or going back) is instant.
class CatalogController extends ChangeNotifier {
  final YouTubeMusicService _svc;
  CatalogController({YouTubeMusicService? service}) : _svc = service ?? YouTubeMusicService();

  final Map<String, Entry<ArtistPage>> _artists = {};
  final Map<String, Entry<AlbumPage>> _albums = {};
  final Map<String, List<SongItem>> _moreSongs = {};

  Entry<ArtistPage> artist(String id) => _artists[id] ?? const Entry(FeedStatus.idle);
  Entry<AlbumPage> album(String id) => _albums[id] ?? const Entry(FeedStatus.idle);
  List<SongItem> moreSongs(String artistId) => _moreSongs[artistId] ?? const [];

  Future<void> loadArtist(String id, {bool force = false}) async {
    final current = _artists[id];
    if (!force && current != null && (current.status == FeedStatus.loading || current.status == FeedStatus.ready)) return;
    _artists[id] = const Entry(FeedStatus.loading);
    notifyListeners();
    final page = await _svc.artist(id);
    _artists[id] = page == null ? const Entry(FeedStatus.failed) : Entry(FeedStatus.ready, page);
    notifyListeners();
    if (page != null && !_moreSongs.containsKey(id)) {
      // Fill in the rest of the artist's songs without holding up the page.
      final more = await _svc.artistMoreSongs(id, page.name);
      final known = page.topSongs.map((s) => s.videoId).toSet();
      _moreSongs[id] = more.where((s) => !known.contains(s.videoId)).toList();
      notifyListeners();
    }
  }

  Future<void> loadAlbum(String id, {bool force = false}) async {
    final current = _albums[id];
    if (!force && current != null && (current.status == FeedStatus.loading || current.status == FeedStatus.ready)) return;
    _albums[id] = const Entry(FeedStatus.loading);
    notifyListeners();
    final page = await _svc.album(id);
    _albums[id] = page == null ? const Entry(FeedStatus.failed) : Entry(FeedStatus.ready, page);
    notifyListeners();
  }
}
