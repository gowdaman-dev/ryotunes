/// A tonal setting: how fast/high the track plays and how much bass / loudness is added.
class SoundState {
  /// Playback speed, 0.5x to 1.5x.
  final double tempo;

  /// Pitch shift in semitones, -6 to +6.
  final double pitch;

  /// Bass boost, 0 (off) to 1 (maximum).
  final double bass;

  /// Loudness boost, 0 (off) to 1 (maximum).
  final double loudness;
  const SoundState({this.tempo = 1, this.pitch = 0, this.bass = 0, this.loudness = 0});

  static const flat = SoundState();

  bool get isFlat => this == flat;

  SoundState copyWith({double? tempo, double? pitch, double? bass, double? loudness}) =>
      SoundState(tempo: tempo ?? this.tempo, pitch: pitch ?? this.pitch, bass: bass ?? this.bass, loudness: loudness ?? this.loudness);

  Map<String, dynamic> toJson() => {'tempo': tempo, 'pitch': pitch, 'bass': bass, 'loudness': loudness};

  factory SoundState.fromJson(Map<String, dynamic> j) => SoundState(
        tempo: ((j['tempo'] as num?) ?? 1).toDouble().clamp(0.5, 1.5),
        pitch: ((j['pitch'] as num?) ?? 0).toDouble().clamp(-6, 6),
        bass: ((j['bass'] as num?) ?? 0).toDouble().clamp(0, 1),
        loudness: ((j['loudness'] as num?) ?? 0).toDouble().clamp(0, 1),
      );

  @override
  bool operator ==(Object other) => other is SoundState && other.tempo == tempo && other.pitch == pitch && other.bass == bass && other.loudness == loudness;

  @override
  int get hashCode => Object.hash(tempo, pitch, bass, loudness);
}

class SoundPreset {
  final String name;
  final SoundState state;
  final bool builtIn;
  const SoundPreset(this.name, this.state, {this.builtIn = false});

  Map<String, dynamic> toJson() => {'name': name, ...state.toJson()};
  factory SoundPreset.fromJson(Map<String, dynamic> j) => SoundPreset(j['name'] as String, SoundState.fromJson(j));
}

/// Presets that ship with the app.
const builtInSoundPresets = [
  SoundPreset('Flat', SoundState.flat, builtIn: true),
  SoundPreset('Slowed', SoundState(tempo: 0.85, pitch: -3), builtIn: true),
  SoundPreset('Nightcore', SoundState(tempo: 1.25, pitch: 4), builtIn: true),
  SoundPreset('Bass Boost', SoundState(bass: 0.8), builtIn: true),
  SoundPreset('Loud', SoundState(loudness: 0.7, bass: 0.25), builtIn: true),
];
