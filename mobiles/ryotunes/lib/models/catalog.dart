import 'song.dart';

/// A card on an artist page or in search: an album or another artist.
class CatalogItem {
  /// `album` or `artist`.
  final String kind;
  final String id;
  final String title;
  final String? subtitle;
  final String? thumbnail;
  const CatalogItem({required this.kind, required this.id, required this.title, this.subtitle, this.thumbnail});
  bool get isArtist => kind == 'artist';
}

class CatalogSection {
  final String title;
  final List<CatalogItem> items;
  const CatalogSection(this.title, this.items);
}

class ArtistPage {
  final String id;
  final String name;
  final String? thumbnail;
  final String? description;
  final String? audience;
  final List<SongItem> topSongs;
  final List<CatalogSection> sections;
  const ArtistPage({required this.id, required this.name, this.thumbnail, this.description, this.audience, this.topSongs = const [], this.sections = const []});
}

class AlbumPage {
  final String id;
  final String title;
  final String artist;
  final List<ArtistRef> artistRefs;
  final String? type;
  final String? year;
  final String? info;
  final String? thumbnail;
  final List<SongItem> tracks;
  const AlbumPage({required this.id, required this.title, required this.artist, this.artistRefs = const [], this.type, this.year, this.info, this.thumbnail, this.tracks = const []});
}
