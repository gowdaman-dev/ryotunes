import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lyrics.dart';
import '../models/song.dart';

/// Lyrics from LRCLIB (free, no key; the same provider the desktop app uses).
/// Returns null when no lyrics exist; throws only on network failure so callers can offer a retry.
class LyricsService {
  static const _base = 'https://lrclib.net/api';
  static const _headers = {'User-Agent': 'Ryotunes Mobile (https://github.com/ryoku-dev/ryotunes)'};
  final http.Client _http = http.Client();

  Future<Lyrics?> fetch(SongItem song) async {
    final title = cleanTitle(song.title);
    final artist = primaryArtist(song.artists);
    final seconds = _seconds(song.duration);

    // 1) exact lookup
    final exact = await _get('$_base/get', {
      'track_name': title,
      'artist_name': artist,
      if (song.album != null && song.album!.isNotEmpty) 'album_name': cleanTitle(song.album!),
      if (seconds != null) 'duration': '$seconds',
    });
    final fromExact = _parse(exact);
    if (fromExact != null) return fromExact;

    // 2) fuzzy search, best candidate by duration proximity, preferring synced lyrics
    final results = await _get('$_base/search', {'track_name': title, 'artist_name': artist}) ??
        await _get('$_base/search', {'q': '$title $artist'});
    if (results is! List || results.isEmpty) return null;
    final candidates = results.whereType<Map<String, dynamic>>().where((r) => (r['instrumental'] ?? false) != true).toList();
    candidates.sort((a, b) {
      final syncedA = (a['syncedLyrics'] as String?)?.isNotEmpty == true ? 0 : 1;
      final syncedB = (b['syncedLyrics'] as String?)?.isNotEmpty == true ? 0 : 1;
      if (syncedA != syncedB) return syncedA - syncedB;
      return _delta(a, seconds).compareTo(_delta(b, seconds));
    });
    for (final c in candidates) {
      // Reject lyrics for what is plainly a different song length (>12s off) when we know ours.
      if (seconds != null && _delta(c, seconds) > 12) continue;
      final parsed = _parse(c);
      if (parsed != null) return parsed;
    }
    return null;
  }

  double _delta(Map<String, dynamic> r, int? seconds) {
    if (seconds == null) return 0;
    final d = (r['duration'] as num?)?.toDouble();
    return d == null ? 999 : (d - seconds).abs();
  }

  Future<dynamic> _get(String url, Map<String, String> query) async {
    final res = await _http.get(Uri.parse(url).replace(queryParameters: query), headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw Exception('LRCLIB ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Lyrics? _parse(dynamic json) {
    if (json is! Map<String, dynamic> || json['instrumental'] == true) return null;
    final synced = json['syncedLyrics'] as String?;
    if (synced != null && synced.trim().isNotEmpty) {
      final lines = parseLrc(synced);
      if (lines.isNotEmpty) return Lyrics(lines, synced: true);
    }
    final plain = json['plainLyrics'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      final lines = plain.split('\n').map((l) => LyricLine(Duration.zero, l.trim())).toList();
      return Lyrics(lines, synced: false);
    }
    return null;
  }

  int? _seconds(String? d) {
    if (d == null) return null;
    final parts = d.split(':').map(int.tryParse).toList();
    if (parts.contains(null)) return null;
    if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
    if (parts.length == 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    return null;
  }

  /// `[mm:ss.xx] text` lines (a line may carry several timestamps). Empty lines are kept as breaks.
  @visibleForTesting
  static List<LyricLine> parseLrc(String lrc) {
    final stamp = RegExp(r'\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\]');
    final out = <LyricLine>[];
    for (final raw in lrc.split('\n')) {
      final matches = stamp.allMatches(raw).toList();
      if (matches.isEmpty) continue;
      final text = raw.substring(matches.last.end).trim();
      for (final m in matches) {
        final frac = m.group(3);
        final ms = frac == null ? 0 : int.parse(frac.padRight(3, '0').substring(0, 3));
        out.add(LyricLine(Duration(minutes: int.parse(m.group(1)!), seconds: int.parse(m.group(2)!), milliseconds: ms), text));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  /// Strip decorations streaming titles carry: `(feat. X)`, `[From "Film"]`, `- Remastered`, etc.
  @visibleForTesting
  static String cleanTitle(String title) {
    var t = title;
    t = t.replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '');
    t = t.replaceAll(RegExp(r'\s+-\s+(from|remaster|remastered|official|lyric|lyrical|audio|video|radio|single|version).*', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s*(feat\.?|ft\.?|featuring)\s.*', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? title.trim() : t;
  }

  @visibleForTesting
  static String primaryArtist(String artists) {
    final first = artists.split(RegExp(r',|&|\band\b|\bfeat\.?\b|\bx\b', caseSensitive: false)).first.trim();
    return first.isEmpty ? artists.trim() : first;
  }
}
