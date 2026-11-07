import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/youtube_music_service.dart';

enum AudioQuality { high, dataSaver }

/// App-wide preferences that persist on the device.
class SettingsController extends ChangeNotifier {
  static const _themeKey = 'settings.theme';
  static const _qualityKey = 'settings.quality';

  ThemeMode _themeMode = ThemeMode.system;
  AudioQuality _quality = AudioQuality.high;

  ThemeMode get themeMode => _themeMode;
  AudioQuality get quality => _quality;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey);
      _themeMode = ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system);
      final quality = prefs.getString(_qualityKey);
      _quality = AudioQuality.values.firstWhere((q) => q.name == quality, orElse: () => AudioQuality.high);
      YouTubeMusicService.dataSaver = _quality == AudioQuality.dataSaver;
    } catch (e) {
      debugPrint('Settings load failed: $e');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString(_themeKey, mode.name);
  }

  Future<void> setQuality(AudioQuality quality) async {
    _quality = quality;
    YouTubeMusicService.dataSaver = quality == AudioQuality.dataSaver;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString(_qualityKey, quality.name);
  }
}
