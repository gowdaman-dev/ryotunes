import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound.dart';
import '../services/audio_handler.dart';

/// The current sound setting plus the user's own saved presets, kept on the device.
class SoundController extends ChangeNotifier {
  static const _key = 'sound.v1';
  final RyotunesAudioHandler? _handler;

  SoundState _state = SoundState.flat;
  final List<SoundPreset> _custom = [];

  SoundController({RyotunesAudioHandler? handler}) : _handler = handler;

  SoundState get state => _state;
  List<SoundPreset> get customPresets => List.unmodifiable(_custom);
  List<SoundPreset> get presets => [...builtInSoundPresets, ..._custom];

  /// The preset whose values equal the current state, if any.
  SoundPreset? get activePreset {
    for (final p in presets) {
      if (p.state == _state) return p;
    }
    return null;
  }

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _state = SoundState.fromJson((data['current'] as Map?)?.cast<String, dynamic>() ?? const {});
        _custom
          ..clear()
          ..addAll(((data['presets'] as List?) ?? const []).map((e) => SoundPreset.fromJson((e as Map).cast<String, dynamic>())));
      }
    } catch (e) {
      debugPrint('Sound settings load failed: $e');
    }
    await _handler?.applySound(_state);
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      (await SharedPreferences.getInstance()).setString(_key, jsonEncode({'current': _state.toJson(), 'presets': _custom.map((p) => p.toJson()).toList()}));
    } catch (e) {
      debugPrint('Sound settings save failed: $e');
    }
  }

  void set(SoundState state) {
    _state = state;
    _handler?.applySound(state);
    notifyListeners();
    _save();
  }

  void setTempo(double v) => set(_state.copyWith(tempo: v));
  void setPitch(double v) => set(_state.copyWith(pitch: v));
  void setBass(double v) => set(_state.copyWith(bass: v));
  void setLoudness(double v) => set(_state.copyWith(loudness: v));
  void reset() => set(SoundState.flat);

  void apply(SoundPreset preset) => set(preset.state);

  /// Save the current setting under [name]; saving over an existing custom name replaces it.
  void savePreset(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || builtInSoundPresets.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) return;
    _custom.removeWhere((p) => p.name.toLowerCase() == trimmed.toLowerCase());
    _custom.add(SoundPreset(trimmed, _state));
    notifyListeners();
    _save();
  }

  void deletePreset(String name) {
    _custom.removeWhere((p) => p.name == name);
    notifyListeners();
    _save();
  }
}
