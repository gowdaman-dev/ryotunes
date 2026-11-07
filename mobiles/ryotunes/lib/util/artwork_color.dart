import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

final Map<String, Color> _cache = {};

/// Average colour of an image, boosted slightly so it reads as a tint rather than mud.
Future<Color?> artworkColor(String? url) async {
  if (url == null || url.isEmpty) return null;
  final cached = _cache[url];
  if (cached != null) return cached;
  try {
    final provider = ResizeImage(NetworkImage(url), width: 12, height: 12);
    final stream = provider.resolve(ImageConfiguration.empty);
    final done = Completer<ui.Image>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!done.isCompleted) done.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (e, _) {
        if (!done.isCompleted) done.completeError(e);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    final image = await done.future.timeout(const Duration(seconds: 8));
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    double r = 0, g = 0, b = 0, weight = 0;
    for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
      final pr = data.getUint8(i).toDouble();
      final pg = data.getUint8(i + 1).toDouble();
      final pb = data.getUint8(i + 2).toDouble();
      final mx = [pr, pg, pb].reduce((a, b) => a > b ? a : b);
      final mn = [pr, pg, pb].reduce((a, b) => a < b ? a : b);
      if (mx < 50) continue; // skip letterbox bars / shadows
      final sat = (mx - mn) / 255;
      final w = 0.05 + sat * sat; // strongly favour saturated pixels
      r += pr * w; g += pg * w; b += pb * w; weight += w;
    }
    if (weight == 0) return null;
    final hsl = HSLColor.fromColor(Color.fromRGBO((r / weight).round(), (g / weight).round(), (b / weight).round(), 1));
    final out = hsl.withSaturation((hsl.saturation * 1.3).clamp(0.35, 1.0)).withLightness(hsl.lightness.clamp(0.28, 0.5)).toColor();
    return _cache[url] = out;
  } catch (_) {
    return null;
  }
}
