class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

class Lyrics {
  final List<LyricLine> lines;

  /// True when lines carry real timestamps (LRC); false for plain text shown without highlighting.
  final bool synced;
  const Lyrics(this.lines, {required this.synced});

  /// Index of the line being sung at [position], or -1 before the first line.
  int activeIndex(Duration position) {
    if (!synced || lines.isEmpty) return -1;
    var lo = 0, hi = lines.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= position) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }
}
