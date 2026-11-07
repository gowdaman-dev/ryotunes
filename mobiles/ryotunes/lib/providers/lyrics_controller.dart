import 'package:flutter/foundation.dart';
import '../models/lyrics.dart';
import '../models/song.dart';
import '../services/lyrics_service.dart';

enum LyricsStatus { idle, loading, ready, unavailable, failed }

/// Lyrics for whichever song is playing; cached per video so skipping back is instant.
class LyricsController extends ChangeNotifier {
  final LyricsService _service = LyricsService();
  final Map<String, Lyrics?> _cache = {};

  String? _videoId;
  LyricsStatus _status = LyricsStatus.idle;
  Lyrics? _lyrics;

  LyricsStatus get status => _status;
  Lyrics? get lyrics => _lyrics;
  String? get videoId => _videoId;

  /// Forget fetched lyrics so they are looked up again.
  void clearCache() {
    _cache.clear();
    _videoId = null;
    _lyrics = null;
    _status = LyricsStatus.idle;
    notifyListeners();
  }

  Future<void> load(SongItem song, {bool force = false}) async {
    if (!force && _videoId == song.videoId && _status != LyricsStatus.failed) return;
    _videoId = song.videoId;
    if (!force && _cache.containsKey(song.videoId)) {
      _lyrics = _cache[song.videoId];
      _status = _lyrics == null ? LyricsStatus.unavailable : LyricsStatus.ready;
      notifyListeners();
      return;
    }
    _lyrics = null;
    _status = LyricsStatus.loading;
    notifyListeners();
    try {
      final result = await _service.fetch(song);
      if (_videoId != song.videoId) return; // user moved on
      _cache[song.videoId] = result;
      _lyrics = result;
      _status = result == null ? LyricsStatus.unavailable : LyricsStatus.ready;
    } catch (e) {
      if (_videoId != song.videoId) return;
      debugPrint('Lyrics failed: $e');
      _status = LyricsStatus.failed;
    }
    notifyListeners();
  }
}
