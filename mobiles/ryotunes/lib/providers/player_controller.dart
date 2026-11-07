import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/audio_handler.dart';
import '../services/youtube_music_service.dart';

enum LoopSetting { off, all, one }

/// Why the current track isn't playing: it can't be streamed, or the device is offline.
enum PlaybackError { none, unavailable, offline }

class PlayerController extends ChangeNotifier {
  final YouTubeMusicService _yt;
  final void Function(SongItem song)? onPlay;
  final bool autoSkipUnplayable;
  final Future<bool> Function() _isOnline;
  final Random _random = Random();

  SongItem? _now;
  bool _paused = true;
  bool _loading = false;
  double _position = 0;
  double _duration = 0;
  double _volume = 1.0;
  bool _shuffle = false;
  LoopSetting _repeat = LoopSetting.off;

  /// Order the user queued things in; restored when shuffle is switched off.
  List<SongItem> _original = [];
  /// Order actually being played (== [_original] unless shuffled).
  List<SongItem> _queue = [];
  int _index = -1;
  int _loadSeq = 0;
  bool _completionHandled = false;
  PlaybackError _error = PlaybackError.none;
  int _consecutiveFailures = 0;

  SongItem? get now => _now;
  bool get paused => _paused;
  bool get loading => _loading;
  double get position => _position;
  double get duration => _duration;
  double get volume => _volume;
  bool get shuffle => _shuffle;
  LoopSetting get repeat => _repeat;
  PlaybackError get error => _error;
  List<SongItem> get queue => List.unmodifiable(_queue);
  int get index => _index;
  bool get hasNow => _now != null;
  bool get hasNext => _index + 1 < _queue.length;
  bool get hasPrevious => _index > 0;

  PlayerController({this.onPlay, YouTubeMusicService? service, this.autoSkipUnplayable = true, Future<bool> Function()? connectivityCheck})
      : _yt = service ?? YouTubeMusicService(),
        _isOnline = connectivityCheck ?? _hasInternet {
    final h = audioHandler;
    if (h == null) return;
    h.onSkipNext = () async => next();
    h.onSkipPrevious = () async => prev();
    h.player.positionStream.listen((p) {
      _position = p.inMilliseconds / 1000.0;
      notifyListeners();
    });
    h.player.durationStream.listen((d) {
      if (d != null) _duration = d.inMilliseconds / 1000.0;
      notifyListeners();
    });
    h.player.playerStateStream.listen((s) {
      _paused = !s.playing;
      if (s.processingState == ProcessingState.completed && !_completionHandled) {
        _completionHandled = true;
        _onCompleted();
      }
      notifyListeners();
    });
    h.player.setVolume(_volume);
  }

  // --- loading -------------------------------------------------------------------------------

  static Future<bool> _hasInternet() async {
    try {
      final r = await InternetAddress.lookup('www.youtube.com').timeout(const Duration(seconds: 3));
      return r.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadAndPlay(SongItem item) async {
    final seq = ++_loadSeq;
    _completionHandled = false;
    _error = PlaybackError.none;
    onPlay?.call(item);
    _now = item;
    _paused = false;
    _loading = true;
    _position = 0;
    _duration = _parseDuration(item.duration);
    notifyListeners();

    var started = false;
    try {
      final h = audioHandler;
      if (h != null) {
        // Try each source in turn; a source that resolves but won't open falls through to the next.
        await for (final candidate in _yt.streamCandidates(item.videoId)) {
          if (seq != _loadSeq) return; // a newer track was requested meanwhile
          try {
            await h.loadSong(item, candidate.url, headers: candidate.headers);
            started = true;
            break;
          } catch (e) {
            debugPrint('${candidate.source} source failed to open: $e');
            _yt.invalidateStream(item.videoId);
          }
        }
      }
      if (seq != _loadSeq) return;
      if (started) {
        _consecutiveFailures = 0;
        await h!.player.setLoopMode(_repeat == LoopSetting.one ? LoopMode.one : LoopMode.off);
        _loading = false;
        notifyListeners();
        // just_audio's play() only completes when playback ends or pauses, so don't await it.
        unawaited(h.play());
        return;
      }
    } catch (e) {
      debugPrint('Playback error: $e');
    }
    if (seq == _loadSeq) await _fail(item, seq);
  }

  Future<void> _fail(SongItem item, int seq) async {
    final online = await _isOnline();
    if (seq != _loadSeq) return;
    _error = online ? PlaybackError.unavailable : PlaybackError.offline;
    _paused = true;
    _loading = false;
    debugPrint('Cannot play ${item.videoId}: ${_error.name}');
    notifyListeners();
    // An unplayable track shouldn't strand the queue: move on, but give up after a few in a row.
    if (autoSkipUnplayable && online && hasNext && ++_consecutiveFailures < 3) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (seq == _loadSeq) next();
    }
  }

  /// Try the current track again (the play button does this after a failure).
  void retry() {
    if (_now == null) return;
    _consecutiveFailures = 0;
    _loadAndPlay(_now!);
  }

  // --- queue ---------------------------------------------------------------------------------

  /// Start playing [items] from [start]. With shuffle on, the rest are shuffled behind the chosen track.
  void setQueue(List<SongItem> items, {int start = 0}) {
    if (items.isEmpty) return;
    _original = [...items];
    final first = items[start.clamp(0, items.length - 1)];
    if (_shuffle) {
      final rest = [...items]..remove(first);
      rest.shuffle(_random);
      _queue = [first, ...rest];
      _index = 0;
    } else {
      _queue = [...items];
      _index = _queue.indexOf(first);
    }
    _loadAndPlay(_queue[_index]);
  }

  void play(SongItem item) => setQueue([item]);

  void playIndex(int i) {
    if (i < 0 || i >= _queue.length) return;
    _index = i;
    _loadAndPlay(_queue[i]);
  }

  /// Insert [song] right after the current track.
  void playNext(SongItem song) {
    if (_queue.isEmpty) return setQueue([song]);
    final at = _index + 1;
    _queue.insert(at, song);
    _original.add(song);
    notifyListeners();
  }

  void addToQueue(SongItem song) {
    if (_queue.isEmpty) return setQueue([song]);
    _queue.add(song);
    _original.add(song);
    notifyListeners();
  }

  void removeFromQueue(int i) {
    if (i < 0 || i >= _queue.length || i == _index) return;
    _original.remove(_queue[i]);
    _queue.removeAt(i);
    if (i < _index) _index--;
    notifyListeners();
  }

  void moveInQueue(int from, int to) {
    if (from == _index || from < 0 || from >= _queue.length) return;
    final song = _queue.removeAt(from);
    var target = to > from ? to - 1 : to;
    target = target.clamp(0, _queue.length);
    _queue.insert(target, song);
    if (from < _index && target >= _index) {
      _index--;
    } else if (from > _index && target <= _index) {
      _index++;
    }
    notifyListeners();
  }

  void clearUpcoming() {
    if (_index < 0 || _index >= _queue.length) return;
    final current = _queue[_index];
    _queue = [current];
    _original = [current];
    _index = 0;
    notifyListeners();
  }

  // --- transport -----------------------------------------------------------------------------

  void togglePause() {
    final h = audioHandler;
    if (_now == null) return;
    if (_error != PlaybackError.none) return retry();
    if (h == null) return;
    if (_paused) {
      h.play();
    } else {
      h.pause();
    }
  }

  Future<void> seek(double seconds) async {
    _position = seconds.clamp(0, _duration);
    notifyListeners();
    await audioHandler?.seek(Duration(milliseconds: (_position * 1000).toInt()));
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0, 1);
    await audioHandler?.player.setVolume(_volume);
    notifyListeners();
  }

  void next() {
    if (_queue.isEmpty) return;
    if (hasNext) {
      playIndex(_index + 1);
    } else if (_repeat == LoopSetting.all) {
      if (_shuffle && _queue.length > 2) {
        // New lap: reshuffle, but don't open with the track that just ended.
        final last = _queue[_index];
        final lap = [..._queue]..shuffle(_random);
        if (lap.first == last) lap.add(lap.removeAt(0));
        _queue = lap;
      }
      playIndex(0);
    } else {
      // End of the queue: park on the last track, paused at the start.
      audioHandler?.pause();
      seek(0);
    }
  }

  void prev() {
    if (_queue.isEmpty) return;
    // Like every player: a restart if we're a few seconds in, otherwise the previous track.
    if (_position > 3 || (!hasPrevious && _repeat != LoopSetting.all)) {
      seek(0);
    } else if (hasPrevious) {
      playIndex(_index - 1);
    } else {
      playIndex(_queue.length - 1);
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_queue.isNotEmpty && _index >= 0) {
      final current = _queue[_index];
      if (_shuffle) {
        final rest = [..._queue]..removeAt(_index);
        final played = rest.sublist(0, min(_index, rest.length));
        final upcoming = rest.sublist(min(_index, rest.length))..shuffle(_random);
        _queue = [...played, current, ...upcoming];
      } else {
        _queue = [..._original];
        _index = max(0, _queue.indexOf(current));
      }
    }
    notifyListeners();
  }

  void cycleRepeat() {
    _repeat = LoopSetting.values[(_repeat.index + 1) % LoopSetting.values.length];
    // Only "one" is handled natively (loops the loaded track); "all" is queue-level and handled in next().
    audioHandler?.player.setLoopMode(_repeat == LoopSetting.one ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  void _onCompleted() {
    // LoopSetting.one never reaches here: the player loops the track itself.
    next();
  }

  double _parseDuration(String? d) {
    if (d == null) return 0;
    final parts = d.split(':').map((e) => double.tryParse(e) ?? 0).toList();
    if (parts.length == 2) return parts[0] * 60 + parts[1];
    if (parts.length == 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
    return 0;
  }
}
