import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/player_controller.dart';

/// Mirrors what's playing onto the Android home-screen widgets. Only reacts to changes of song or
/// play/pause (not to every position tick), and batches rapid changes together.
class WidgetSync {
  static const _providers = ['dev.ryoku.ryotunes.NowPlayingWidget', 'dev.ryoku.ryotunes.CompactWidget'];

  final PlayerController _player;
  String? _lastKey;
  Timer? _debounce;

  WidgetSync(this._player) {
    _player.addListener(_onChange);
    _onChange();
  }

  void _onChange() {
    final key = '${_player.now?.videoId}|${_player.paused}|${_player.error.name}';
    if (key == _lastKey) return;
    _lastKey = key;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _push);
  }

  Future<void> _push() async {
    try {
      final song = _player.now;
      String? artPath;
      final thumb = song?.thumbnail;
      if (thumb != null && thumb.isNotEmpty) {
        try {
          artPath = (await DefaultCacheManager().getSingleFile(thumb)).path;
        } catch (_) {
          artPath = null; // fall back to the app logo
        }
      }
      await HomeWidget.saveWidgetData<String>('widget_title', song?.title);
      await HomeWidget.saveWidgetData<String>('widget_artist', song?.artists);
      await HomeWidget.saveWidgetData<String>('widget_art', artPath);
      await HomeWidget.saveWidgetData<bool>('widget_playing', song != null && !_player.paused);
      for (final name in _providers) {
        await HomeWidget.updateWidget(qualifiedAndroidName: name);
      }
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  void dispose() {
    _debounce?.cancel();
    _player.removeListener(_onChange);
  }
}
