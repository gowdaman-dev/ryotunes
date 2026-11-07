/// An artist a song credits, with the YouTube Music browse id of their page.
class ArtistRef {
  final String name;
  final String id;
  const ArtistRef(this.name, this.id);
  Map<String, dynamic> toJson() => {'name': name, 'id': id};
  factory ArtistRef.fromJson(Map<String, dynamic> j) => ArtistRef(j['name'] as String, j['id'] as String);
}

/// Mirrors desktop SongItem.
class SongItem {
  final String videoId;
  final String title;
  final String artists;
  final String? album;
  final String? duration;
  final String? thumbnail;
  final bool isUpload;
  final bool isVideo;
  final String? albumId;
  final List<ArtistRef> artistRefs;
  final bool queued;
  final bool queuedEnd;
  final bool autoplay;

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'artists': artists,
        'album': album,
        'duration': duration,
        'thumbnail': thumbnail,
        'isUpload': isUpload,
        'isVideo': isVideo,
        'albumId': albumId,
        'artistRefs': artistRefs.map((a) => a.toJson()).toList(),
      };

  factory SongItem.fromJson(Map<String, dynamic> j) => SongItem(
        videoId: j['videoId'] as String,
        title: j['title'] as String,
        artists: (j['artists'] as String?) ?? '',
        album: j['album'] as String?,
        duration: j['duration'] as String?,
        thumbnail: j['thumbnail'] as String?,
        isUpload: (j['isUpload'] as bool?) ?? false,
        isVideo: (j['isVideo'] as bool?) ?? false,
        albumId: j['albumId'] as String?,
        artistRefs: ((j['artistRefs'] as List?) ?? const []).map((e) => ArtistRef.fromJson(e as Map<String, dynamic>)).toList(),
      );

  const SongItem({
    required this.videoId,
    required this.title,
    required this.artists,
    this.album,
    this.duration,
    this.thumbnail,
    this.isUpload = false,
    this.isVideo = false,
    this.albumId,
    this.artistRefs = const [],
    this.queued = false,
    this.queuedEnd = false,
    this.autoplay = false,
  });
}

/// Mirrors desktop BrowseItem.
class BrowseItem {
  final String kind; // song, album, artist, playlist, radio
  final String id;
  final String title;
  final String? subtitle;
  final String? thumbnail;
  final String? duration;
  final bool isVideo;
  final bool isUpload;

  const BrowseItem({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    this.thumbnail,
    this.duration,
    this.isVideo = false,
    this.isUpload = false,
  });
}

class Section {
  final String title;
  final List<BrowseItem> items;
  final String? continuation;
  const Section({required this.title, required this.items, this.continuation});
}

class HomePage {
  final List<String> chips;
  final List<Section> sections;
  final String? continuation;
  const HomePage({this.chips = const [], this.sections = const [], this.continuation});
}