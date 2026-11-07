// Hits the real YouTube Music API. Run with:  LIVE=1 flutter test test/catalog_live_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryotunes/services/youtube_music_service.dart';

void main() {
  final live = Platform.environment['LIVE'] == '1';
  final skip = live ? false : 'set LIVE=1 to run against the network';

  setUpAll(() => HttpOverrides.global = null);

  test('song rows carry artist and album ids', () async {
    final songs = await YouTubeMusicService().search('Pavazha Malli');
    expect(songs, isNotEmpty);
    final s = songs.first;
    expect(s.artistRefs, isNotEmpty);
    expect(s.artistRefs.first.id, startsWith('UC'));
    expect(s.albumId, startsWith('MPRE'));
    expect(s.thumbnail, contains('544'));
  }, skip: skip);

  test('artist page has a portrait, top songs and shelves', () async {
    final a = await YouTubeMusicService().artist('UCJPuVnth4cFX-2QJ6HxciaA');
    expect(a, isNotNull);
    expect(a!.name, 'Sai Abhyankkar');
    expect(a.thumbnail, contains('800'));
    expect(a.topSongs.length, greaterThanOrEqualTo(3));
    expect(a.topSongs.first.artistRefs, isNotEmpty);
    expect(a.sections.map((s) => s.title), contains('Albums'));
    final albums = a.sections.firstWhere((s) => s.title == 'Albums').items;
    expect(albums.first.kind, 'album');
    expect(albums.first.id, startsWith('MPRE'));
    // ignore: avoid_print
    print('artist: ${a.name} | top=${a.topSongs.length} | sections=${a.sections.map((s) => '${s.title}(${s.items.length})').join(', ')} | audience=${a.audience}');
  }, skip: skip);

  test('album page has tracks with artists, durations and cover fallback', () async {
    final al = await YouTubeMusicService().album('MPREb_QUj6R3hDDgP');
    expect(al, isNotNull);
    expect(al!.tracks, isNotEmpty);
    expect(al.artist, isNotEmpty);
    expect(al.artistRefs, isNotEmpty);
    expect(al.tracks.first.artists, isNotEmpty);
    expect(al.tracks.first.duration, isNotNull);
    expect(al.tracks.first.thumbnail, isNotNull);
    expect(al.tracks.first.albumId, 'MPREb_QUj6R3hDDgP');
    // ignore: avoid_print
    print('album: ${al.title} | ${al.type} ${al.year} | ${al.info} | tracks=${al.tracks.length} | first="${al.tracks.first.title}" ${al.tracks.first.duration}');
  }, skip: skip);

  test('artist and album search return browsable items', () async {
    final svc = YouTubeMusicService();
    final artists = await svc.searchArtists('Anirudh');
    final albums = await svc.searchAlbums('Jailer');
    expect(artists, isNotEmpty);
    expect(artists.first.isArtist, isTrue);
    expect(artists.first.id, startsWith('UC'));
    expect(albums, isNotEmpty);
    expect(albums.first.id, startsWith('MPRE'));
    // ignore: avoid_print
    print('artist hit: ${artists.first.title} (${artists.first.subtitle}) | album hit: ${albums.first.title} (${albums.first.subtitle})');
  }, skip: skip);
}
