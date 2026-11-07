import 'package:flutter_test/flutter_test.dart';
import 'package:ryotunes/models/lyrics.dart';
import 'package:ryotunes/services/lyrics_service.dart';

void main() {
  test('cleanTitle strips decorations', () {
    expect(LyricsService.cleanTitle('Radhimaa [From "Think Indie"] (feat. Sai Smriti)'), 'Radhimaa');
    expect(LyricsService.cleanTitle('Ooroda Oththa Don (From "Baththa")'), 'Ooroda Oththa Don');
    expect(LyricsService.cleanTitle('Namaste'), 'Namaste');
  });

  test('primaryArtist takes the lead artist', () {
    expect(LyricsService.primaryArtist('Sai Abhyankkar, Nargis Teji & Vivek'), 'Sai Abhyankkar');
    expect(LyricsService.primaryArtist('Anirudh Ravichander'), 'Anirudh Ravichander');
  });

  test('parseLrc reads timestamps, multi-stamps and sorts', () {
    final lines = LyricsService.parseLrc('[00:04.28] two\n[00:00.76]one\n[01:00.5][02:00.00] again\nnoise');
    expect(lines.map((l) => l.text), ['one', 'two', 'again', 'again']);
    expect(lines.first.time, const Duration(milliseconds: 760));
    expect(lines[2].time, const Duration(minutes: 1, milliseconds: 500));
  });

  test('activeIndex follows playback position', () {
    final l = Lyrics(LyricsService.parseLrc('[00:10.00]a\n[00:20.00]b\n[00:30.00]c'), synced: true);
    expect(l.activeIndex(const Duration(seconds: 5)), -1);
    expect(l.activeIndex(const Duration(seconds: 10)), 0);
    expect(l.activeIndex(const Duration(seconds: 25)), 1);
    expect(l.activeIndex(const Duration(minutes: 5)), 2);
  });
}
