import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'ry_chip.dart';

class SoundSheet extends StatefulWidget {
  const SoundSheet({super.key});
  @override
  State<SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<SoundSheet> {
  double tempo = 1.0;
  double pitch = 0;
  double reverb = 0;
  double bass = 0;
  double width = 1.0;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sound', style: RyFonts.display(TypeScale.xl, color: scheme.onSurface)),
          const SizedBox(height: Sp.md),
          _slider('Tempo', tempo, 0.25, 2.0, (v) => setState(() => tempo = v), '${tempo.toStringAsFixed(2)}x'),
          _slider('Pitch', pitch, -12, 12, (v) => setState(() => pitch = v), '${pitch.toInt()} st'),
          _slider('Reverb', reverb, 0, 1, (v) => setState(() => reverb = v), reverb.toStringAsFixed(2)),
          _slider('Bass', bass, -6, 12, (v) => setState(() => bass = v), '${bass.toStringAsFixed(1)} dB'),
          _slider('Width', width, 0, 1, (v) => setState(() => width = v), width.toStringAsFixed(2)),
          const SizedBox(height: Sp.md),
          Wrap(spacing: Sp.xs, children: [
            for (final p in ['Flat', 'Slowed+Reverb', 'Nightcore', 'Bass Boost', 'Wide'])
              RyChip(label: p, onTap: () {}),
          ]),
          const SizedBox(height: Sp.md),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, String val) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text(label, style: RyFonts.ui(TypeScale.sm, color: scheme.onSurface)), const Spacer(), Text(val, style: RyFonts.mono(TypeScale.xs, color: scheme.onSurface.withValues(alpha: 0.6)))]),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}