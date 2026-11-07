import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sound.dart';
import '../providers/sound_controller.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'song_menu.dart';

/// Tempo, pitch, bass and loudness for whatever is playing, plus built-in and personal presets.
class SoundSheet extends StatelessWidget {
  const SoundSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sound = context.watch<SoundController>();
    final s = sound.state;
    final active = sound.activePreset;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.pagePad, 20, Sp.pagePad, Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Sound', style: RyFonts.ui(26, weight: FontWeight.w800, color: Colors.white))),
              TextButton(onPressed: s.isFlat ? null : sound.reset, child: const Text('Reset')),
            ]),
            const SizedBox(height: 4),
            _slider(context, 'Tempo', s.tempo, 0.5, 1.5, sound.setTempo, '${s.tempo.toStringAsFixed(2)}x', divisions: 20),
            _slider(context, 'Pitch', s.pitch, -6, 6, (v) => sound.setPitch(v.roundToDouble()), '${s.pitch > 0 ? '+' : ''}${s.pitch.round()} st', divisions: 12),
            _slider(context, 'Bass', s.bass, 0, 1, sound.setBass, '${(s.bass * 100).round()}%'),
            _slider(context, 'Loudness', s.loudness, 0, 1, sound.setLoudness, '${(s.loudness * 100).round()}%'),
            const SizedBox(height: 14),
            Text('Presets', style: RyFonts.ui(TypeScale.md, weight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in sound.presets)
                _PresetChip(
                  preset: p,
                  selected: identical(p, active) || p == active,
                  onTap: () => sound.apply(p),
                  onDelete: p.builtIn ? null : () => sound.deletePreset(p.name),
                ),
              ActionChip(
                avatar: Icon(Icons.add_rounded, size: 18, color: scheme.primary),
                label: const Text('Save current'),
                onPressed: () async {
                  final name = await promptPlaylistName(context, title: 'Save Preset', action: 'Save');
                  if (name != null) sound.savePreset(name);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _slider(BuildContext context, String label, double value, double min, double max, ValueChanged<double> onChanged, String shown, {int? divisions}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: Colors.white)),
          const Spacer(),
          Text(shown, style: RyFonts.mono(TypeScale.sm, color: Colors.white60)),
        ]),
        Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
      ]),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final SoundPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _PresetChip({required this.preset, required this.selected, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.fromLTRB(16, 8, onDelete == null ? 16 : 6, 8),
        decoration: BoxDecoration(color: selected ? scheme.primary : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(preset.name, style: RyFonts.ui(14, weight: FontWeight.w600, color: Colors.white)),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 16, color: Colors.white70))),
          ],
        ]),
      ),
    );
  }
}
