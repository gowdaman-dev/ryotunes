import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/catalog.dart';
import '../models/song.dart';

/// YouTube Music metadata (search) plus direct audio-stream resolution.
///
/// Search goes through the YouTube Music "songs only" filter, the same one the desktop `innertube`
/// crate uses, so results are actual studio/audio tracks with square album art rather than
/// lyric videos or uploads. Playback resolves an audio-only stream URL, so no ads are involved.
class YouTubeMusicService {
  static const _endpoint = 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false';
  static const _clientVersion = '1.20260213.01.00';
  static const _filterSongs = 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';
  static const _filterArtists = 'EgWKAQIgAWoKEAkQChAFEAMQBA%3D%3D';
  static const _filterAlbums = 'EgWKAQIYAWoKEAkQChAFEAMQBA%3D%3D';
  static const _browseEndpoint = 'https://music.youtube.com/youtubei/v1/browse?prettyPrint=false';
  static const _headers = {
    'Content-Type': 'application/json',
    'Origin': 'https://music.youtube.com',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
  };

  final YoutubeExplode _yt = YoutubeExplode();
  final http.Client _http = http.Client();

  Future<Map<String, dynamic>?> _post(String endpoint, Map<String, dynamic> body, {String region = 'IN'}) async {
    try {
      final res = await _http
          .post(
            Uri.parse(endpoint),
            headers: _headers,
            body: jsonEncode({
              'context': {
                'client': {'clientName': 'WEB_REMIX', 'clientVersion': _clientVersion, 'hl': 'en', 'gl': region},
              },
              ...body,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('YT Music request failed: $e');
      return null;
    }
  }

  /// Songs matching [query]; only audio tracks (`MUSIC_VIDEO_TYPE_ATV`), never music videos.
  Future<List<SongItem>> search(String query, {String region = 'IN'}) async {
    final data = await _post(_endpoint, {'query': query, 'params': _filterSongs}, region: region);
    if (data == null) return [];
    final items = <SongItem>[];
    _collect(data, items);
    return items;
  }

  Future<List<CatalogItem>> searchArtists(String query) => _searchCatalog(query, _filterArtists, 'artist');
  Future<List<CatalogItem>> searchAlbums(String query) => _searchCatalog(query, _filterAlbums, 'album');

  Future<List<CatalogItem>> _searchCatalog(String query, String filter, String kind) async {
    final data = await _post(_endpoint, {'query': query, 'params': filter});
    if (data == null) return [];
    final out = <CatalogItem>[];
    void walk(Object? node) {
      if (node is Map<String, dynamic>) {
        final r = node['musicResponsiveListItemRenderer'];
        if (r is Map<String, dynamic>) {
          final item = _catalogFromRow(r, kind);
          if (item != null) out.add(item);
          return;
        }
        node.values.forEach(walk);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    walk(data);
    return out;
  }

  CatalogItem? _catalogFromRow(Map<String, dynamic> r, String kind) {
    final id = r['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
    if (id == null || !(kind == 'artist' ? id.startsWith('UC') : id.startsWith('MPRE'))) return null;
    final cols = (r['flexColumns'] as List?) ?? const [];
    String text(int i) => i >= cols.length ? '' : _runs(cols[i]).map((e) => e['text']).join();
    final title = text(0);
    if (title.isEmpty) return null;
    // Subtitle reads "Album • Artist • 2026" / "Artist • 641K subscribers": drop the leading type word.
    var sub = text(1);
    final parts = sub.split(' • ');
    if (parts.length > 1 && (parts.first == 'Album' || parts.first == 'Single' || parts.first == 'EP' || parts.first == 'Artist')) sub = parts.skip(1).join(' • ');
    return CatalogItem(kind: kind, id: id, title: title, subtitle: sub.isEmpty ? null : sub, thumbnail: _squareArt(r, size: 400));
  }

  List _runs(dynamic column) {
    final c = (column as Map)['musicResponsiveListItemFlexColumnRenderer'] as Map?;
    return ((c?['text'] as Map?)?['runs'] as List?) ?? const [];
  }

  // --- artist & album pages --------------------------------------------------------------------

  /// An artist's page: header, top songs, and album / single / related-artist shelves.
  Future<ArtistPage?> artist(String browseId) async {
    final data = await _post(_browseEndpoint, {'browseId': browseId});
    if (data == null) return null;
    try {
      final header = (data['header'] as Map<String, dynamic>).values.first as Map<String, dynamic>;
      final name = (header['title']['runs'] as List).map((e) => e['text']).join();
      final thumbs = header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
      // The banner comes as a wide crop; ask the CDN for a square one for the round portrait.
      final portrait = thumbs?.isNotEmpty == true ? (thumbs!.last['url'] as String).replaceFirst(RegExp(r'=w\d+-h\d+'), '=w800-h800') : null;
      final desc = ((header['description']?['runs'] as List?) ?? const []).map((e) => e['text']).join();
      final audience = ((header['monthlyListenerCount']?['runs'] as List?) ?? const []).map((e) => e['text']).join();
      final tabs = data['contents']['singleColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'] as List;
      final top = <SongItem>[];
      final sections = <CatalogSection>[];
      for (final c in tabs.cast<Map<String, dynamic>>()) {
        final shelf = c['musicShelfRenderer'];
        if (shelf is Map<String, dynamic>) {
          for (final row in (shelf['contents'] as List).cast<Map<String, dynamic>>()) {
            final r = row['musicResponsiveListItemRenderer'];
            if (r is Map<String, dynamic>) {
              final song = _parseRow(r);
              if (song != null) top.add(song);
            }
          }
        }
        final carousel = c['musicCarouselShelfRenderer'];
        if (carousel is Map<String, dynamic>) {
          final title = carousel['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'] as String?;
          if (title == null || title == 'Videos' || title == 'Featured on') continue;
          final items = <CatalogItem>[];
          for (final it in (carousel['contents'] as List).cast<Map<String, dynamic>>()) {
            final two = it['musicTwoRowItemRenderer'];
            if (two is Map<String, dynamic>) {
              final item = _catalogFromTwoRow(two);
              if (item != null) items.add(item);
            }
          }
          if (items.isNotEmpty) sections.add(CatalogSection(title, items));
        }
      }
      return ArtistPage(
        id: browseId,
        name: name,
        thumbnail: portrait,
        description: desc.isEmpty ? null : desc,
        audience: audience.isEmpty ? null : audience,
        topSongs: top,
        sections: sections,
      );
    } catch (e) {
      debugPrint('Artist parse failed: $e');
      return null;
    }
  }

  /// More of an artist's songs than the 5 on their page, via search, keeping only songs they're credited on.
  Future<List<SongItem>> artistMoreSongs(String artistId, String name) async {
    final results = await search('$name songs');
    return results.where((s) => s.artistRefs.any((a) => a.id == artistId)).toList();
  }

  CatalogItem? _catalogFromTwoRow(Map<String, dynamic> two) {
    final id = two['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
    if (id == null) return null;
    final kind = id.startsWith('MPRE') ? 'album' : (id.startsWith('UC') ? 'artist' : null);
    if (kind == null) return null;
    final title = ((two['title']?['runs'] as List?) ?? const []).map((e) => e['text']).join();
    final subtitle = ((two['subtitle']?['runs'] as List?) ?? const []).map((e) => e['text']).join();
    final thumbs = two['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
    final thumb = thumbs?.isNotEmpty == true ? (thumbs!.last['url'] as String).replaceFirst(RegExp(r'=w\d+-h\d+'), '=w400-h400') : null;
    return CatalogItem(kind: kind, id: id, title: title, subtitle: subtitle.isEmpty ? null : subtitle, thumbnail: thumb);
  }

  /// An album / single / EP page with its tracks.
  Future<AlbumPage?> album(String browseId) async {
    final data = await _post(_browseEndpoint, {'browseId': browseId});
    if (data == null) return null;
    try {
      final two = data['contents']['twoColumnBrowseResultsRenderer'] as Map<String, dynamic>;
      final header = two['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'][0]['musicResponsiveHeaderRenderer'] as Map<String, dynamic>;
      final title = (header['title']['runs'] as List).map((e) => e['text']).join();
      final sub = ((header['subtitle']?['runs'] as List?) ?? const []).map((e) => e['text'] as String).where((t) => t.trim() != '•').toList();
      final info = ((header['secondSubtitle']?['runs'] as List?) ?? const []).map((e) => e['text'] as String).where((t) => t.trim() != '•').join(' · ');
      final strap = ((header['straplineTextOne']?['runs'] as List?) ?? const []).cast<Map<String, dynamic>>();
      final refs = <ArtistRef>[
        for (final r in strap)
          if ((r['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?)?.startsWith('UC') ?? false) ArtistRef(r['text'] as String, r['navigationEndpoint']['browseEndpoint']['browseId'] as String),
      ];
      final artist = strap.map((e) => e['text']).join();
      final thumbs = header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
      final cover = thumbs?.isNotEmpty == true ? (thumbs!.last['url'] as String).replaceFirst(RegExp(r'=w\d+-h\d+'), '=w800-h800') : null;

      final tracks = <SongItem>[];
      final secondary = (two['secondaryContents']?['sectionListRenderer']?['contents'] as List?) ?? const [];
      for (final c in secondary.cast<Map<String, dynamic>>()) {
        final shelf = c['musicShelfRenderer'];
        if (shelf is! Map<String, dynamic>) continue;
        for (final row in (shelf['contents'] as List).cast<Map<String, dynamic>>()) {
          final r = row['musicResponsiveListItemRenderer'];
          if (r is! Map<String, dynamic>) continue;
          final song = _parseRow(r, fallbackArtists: artist, fallbackRefs: refs, fallbackAlbum: title, fallbackAlbumId: browseId, fallbackThumb: cover);
          if (song != null) tracks.add(song);
        }
      }
      return AlbumPage(
        id: browseId,
        title: title,
        artist: artist,
        artistRefs: refs,
        type: sub.isNotEmpty ? sub.first : null,
        year: sub.length > 1 ? sub.last : null,
        info: info.isEmpty ? null : info,
        thumbnail: cover,
        tracks: tracks,
      );
    } catch (e) {
      debugPrint('Album parse failed: $e');
      return null;
    }
  }

  /// Fallback for songs with no official audio track (indie uploads, covers, regional releases).
  /// These are ordinary YouTube uploads, flagged `isUpload` so the UI can label them.
  Future<List<SongItem>> searchUploads(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results
          .where((v) => !v.isLive && v.duration != null && v.duration!.inSeconds >= 60 && v.duration!.inMinutes <= 12)
          .take(15)
          .map((v) => SongItem(
                videoId: v.id.value,
                title: v.title,
                artists: v.author,
                duration: _fmt(v.duration),
                thumbnail: v.thumbnails.highResUrl,
                isUpload: true,
              ))
          .toList();
    } catch (e) {
      debugPrint('Upload search failed: $e');
      return [];
    }
  }

  String _fmt(Duration? d) {
    if (d == null) return '';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _collect(Object? node, List<SongItem> out) {
    if (node is Map<String, dynamic>) {
      final r = node['musicResponsiveListItemRenderer'];
      if (r is Map<String, dynamic>) {
        final song = _parseRow(r);
        if (song != null) out.add(song);
        return;
      }
      for (final v in node.values) {
        _collect(v, out);
      }
    } else if (node is List) {
      for (final v in node) {
        _collect(v, out);
      }
    }
  }

  /// A song row as returned by search, artist shelves and album pages. Album-page rows carry no
  /// artists / art of their own, so the page supplies fallbacks.
  SongItem? _parseRow(Map<String, dynamic> r, {String? fallbackArtists, List<ArtistRef>? fallbackRefs, String? fallbackAlbum, String? fallbackAlbumId, String? fallbackThumb}) {
    final videoId = (r['playlistItemData'] as Map?)?['videoId'] as String?;
    if (videoId == null || !jsonEncode(r).contains('MUSIC_VIDEO_TYPE_ATV')) return null;
    final cols = (r['flexColumns'] as List?) ?? const [];
    final title = _runs(cols.first).map((e) => e['text']).join();
    if (title.isEmpty) return null;

    // Credits column: "Artists • Album • 4:20" in search, just "Artists" on artist shelves.
    final parts = <String>[];
    var current = StringBuffer();
    final refs = <ArtistRef>[];
    String? albumId;
    String? album;
    for (var i = 1; i < cols.length; i++) {
      for (final run in _runs(cols[i])) {
        final text = run['text'] as String;
        final id = run['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
        if (id != null && id.startsWith('UC') && !refs.any((a) => a.id == id)) refs.add(ArtistRef(text, id));
        if (id != null && id.startsWith('MPRE')) {
          albumId = id;
          album = text;
        }
        if (i == 1) {
          if (text.trim() == '•') {
            parts.add(current.toString());
            current = StringBuffer();
          } else {
            current.write(text);
          }
        }
      }
    }
    parts.add(current.toString());
    final fixed = ((r['fixedColumns'] as List?)?.firstOrNull as Map?)?['musicResponsiveListItemFixedColumnRenderer']?['text']?['runs']?[0]?['text'] as String?;
    final durationRe = RegExp(r'^\d+:\d{2}(:\d{2})?$');
    final duration = (parts.length > 1 && durationRe.hasMatch(parts.last.trim())) ? parts.last.trim() : (fixed != null && durationRe.hasMatch(fixed) ? fixed : null);
    final credited = parts.first.trim();
    return SongItem(
      videoId: videoId,
      title: title,
      artists: credited.isNotEmpty ? credited : (fallbackArtists ?? ''),
      album: album ?? (parts.length > 2 ? parts[1] : fallbackAlbum),
      albumId: albumId ?? fallbackAlbumId,
      artistRefs: refs.isNotEmpty ? refs : (fallbackRefs ?? const []),
      duration: duration,
      thumbnail: _squareArt(r) ?? fallbackThumb,
    );
  }

  /// Album art comes as a small `=w60-h60` URL; ask the CDN for a sharp version.
  String? _squareArt(Map<String, dynamic> r, {int size = 544}) {
    final thumbs = (((r['thumbnail'] as Map?)?['musicThumbnailRenderer'] as Map?)?['thumbnail'] as Map?)?['thumbnails'] as List?;
    final url = thumbs?.isNotEmpty == true ? thumbs!.last['url'] as String? : null;
    if (url == null) return null;
    return url.replaceFirst(RegExp(r'=w\d+-h\d+'), '=w$size-h$size');
  }

  // --- audio stream resolution -------------------------------------------------------------
  // Direct audio-only URLs (no ads) from the player endpoint with a visitor session, using the
  // same identity as the desktop `innertube` crate. VISIONOS is the one client whose URLs serve
  // a whole file; ANDROID_VR / IOS URLs return 403 after the first ~1 MB without a PoToken, so
  // they are deliberately not used.
  static const _playerEndpoint = 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';
  static const _visionOs = _StreamClient('VISIONOS', '0.1', '101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15',
      {'osName': 'visionOS', 'osVersion': '1.3.21O771', 'deviceMake': 'Apple', 'deviceModel': 'RealityDevice14,1'});
  /// When true, pick the smallest AAC stream instead of the best one (set from Settings).
  static bool dataSaver = false;

  String? _visitorData;
  final Map<String, StreamCandidate> _streamCache = {};
  String _cacheKey(String videoId) => '$videoId|${dataSaver ? 'saver' : 'high'}';

  Future<String?> _ensureVisitorData({bool refresh = false}) async {
    if (_visitorData != null && !refresh) return _visitorData;
    try {
      final res = await _http
          .post(
            Uri.parse('https://www.youtube.com/youtubei/v1/visitor_id?prettyPrint=false'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'context': {'client': {'clientName': 'WEB', 'clientVersion': '2.20260213.01.00', 'hl': 'en', 'gl': 'IN'}}}),
          )
          .timeout(const Duration(seconds: 10));
      _visitorData = (jsonDecode(res.body)['responseContext']?['visitorData']) as String? ?? _visitorData;
    } catch (e) {
      debugPrint('visitor_id failed: $e');
    }
    return _visitorData;
  }

  /// Forget a cached URL (it expired or the CDN refused it) so the next attempt resolves a fresh one.
  void invalidateStream(String videoId) {
    _streamCache.remove('$videoId|high');
    _streamCache.remove('$videoId|saver');
  }

  /// Playable sources for [videoId], best first. Lazy: the next source is only resolved if the
  /// consumer asks for it because the previous one failed to play.
  Stream<StreamCandidate> streamCandidates(String videoId) async* {
    final cached = _streamCache[_cacheKey(videoId)];
    if (cached != null && cached.expires.isAfter(DateTime.now())) yield cached;

    // 1) VISIONOS with the current visitor session; if refused, retry once with a fresh session.
    var found = await _resolveDirect(videoId, _visionOs, await _ensureVisitorData());
    found ??= await _resolveDirect(videoId, _visionOs, await _ensureVisitorData(refresh: true));
    if (found != null) {
      _streamCache[_cacheKey(videoId)] = found;
      if (cached == null || found.url != cached.url) yield found;
    }

    // 2) Last resort: the youtube_explode client chain.
    final viaExplode = await _resolveExplode(videoId);
    if (viaExplode != null && viaExplode.url != found?.url) yield viaExplode;
  }

  Future<StreamCandidate?> _resolveDirect(String videoId, _StreamClient c, String? visitor) async {
    try {
      final res = await _http
          .post(
            Uri.parse(_playerEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': c.userAgent,
              'X-YouTube-Client-Name': c.id,
              'X-YouTube-Client-Version': c.version,
              if (visitor != null) 'X-Goog-Visitor-Id': visitor,
            },
            body: jsonEncode({
              'context': {
                'client': {'clientName': c.name, 'clientVersion': c.version, 'hl': 'en', 'gl': 'IN', ...c.extra, if (visitor != null) 'visitorData': visitor},
              },
              'videoId': videoId,
              'contentCheckOk': true,
              'racyCheckOk': true,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['playabilityStatus']?['status'] != 'OK') {
        debugPrint('${c.name} refused $videoId: ${data['playabilityStatus']?['status']}');
        return null;
      }
      final formats = ((data['streamingData']?['adaptiveFormats'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .where((f) => (f['mimeType'] as String).startsWith('audio/') && f['url'] != null)
          .toList();
      if (formats.isEmpty) return null;
      // Prefer AAC (audio/mp4) for broad player support. High quality takes the highest bitrate;
      // data saver takes the lowest one that is still listenable (>= 40 kbps).
      int bitrate(Map<String, dynamic> f) => f['bitrate'] as int? ?? 0;
      int rank(Map<String, dynamic> f) {
        final aac = (f['mimeType'] as String).startsWith('audio/mp4') ? 1 << 30 : 0;
        if (!dataSaver) return aac + bitrate(f);
        final usable = bitrate(f) >= 40000;
        return aac + (usable ? (1 << 20) - bitrate(f) ~/ 1000 : 0);
      }
      formats.sort((a, b) => rank(b).compareTo(rank(a)));
      return StreamCandidate(
        url: formats.first['url'] as String,
        headers: {'User-Agent': c.userAgent},
        source: c.name,
        expires: DateTime.now().add(const Duration(hours: 4)),
      );
    } catch (e) {
      debugPrint('Stream via ${c.name} failed: $e');
      return null;
    }
  }

  Future<StreamCandidate?> _resolveExplode(String videoId) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(videoId, ytClients: [YoutubeApiClient.ios, YoutubeApiClient.androidVr]);
      final audio = manifest.audioOnly.toList()..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
      if (audio.isEmpty) return null;
      return StreamCandidate(url: audio.first.url.toString(), headers: const {}, source: 'youtube_explode', expires: DateTime.now().add(const Duration(hours: 1)));
    } catch (e) {
      debugPrint('youtube_explode failed for $videoId: ${e.toString().split('\n').first}');
      return null;
    }
  }

  void dispose() {
    _yt.close();
    _http.close();
  }
}

/// A resolved audio URL plus the headers its CDN expects.
class StreamCandidate {
  final String url;
  final Map<String, String> headers;
  final String source;
  final DateTime expires;
  const StreamCandidate({required this.url, required this.headers, required this.source, required this.expires});
}

class _StreamClient {
  final String name;
  final String version;
  final String id;
  final String userAgent;
  final Map<String, Object> extra;
  const _StreamClient(this.name, this.version, this.id, this.userAgent, this.extra);
}
