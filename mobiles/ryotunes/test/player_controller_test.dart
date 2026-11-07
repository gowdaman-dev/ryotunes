import 'package:flutter_test/flutter_test.dart';
import 'package:ryotunes/models/song.dart';
import 'package:ryotunes/providers/player_controller.dart';
import 'package:ryotunes/services/youtube_music_service.dart';

/// Resolves no streams, so queue logic runs without audio or network.
class _NoStreams extends YouTubeMusicService {
  @override
  Stream<StreamCandidate> streamCandidates(String videoId) => const Stream.empty();
}

SongItem song(String id) => SongItem(videoId: id, title: 'Song $id', artists: 'Artist');

PlayerController make({bool online = true}) => PlayerController(service: _NoStreams(), autoSkipUnplayable: false, connectivityCheck: () async => online);

List<String> ids(PlayerController p) => p.queue.map((s) => s.videoId).toList();

void main() {
  final songs = ['a', 'b', 'c', 'd'].map(song).toList();

  test('setQueue starts at the chosen track', () {
    final p = make()..setQueue(songs, start: 2);
    expect(p.now?.videoId, 'c');
    expect(p.index, 2);
    expect(ids(p), ['a', 'b', 'c', 'd']);
  });

  test('next/prev walk the queue and stop at the ends', () async {
    final p = make()..setQueue(songs);
    p.next();
    p.next();
    expect(p.now?.videoId, 'c');
    p.prev();
    expect(p.now?.videoId, 'b');
    p.playIndex(3);
    p.next(); // end of queue, repeat off: parks on the last track
    expect(p.now?.videoId, 'd');
    expect(p.index, 3);
    p.playIndex(0);
    p.prev(); // at the start with repeat off: stays
    expect(p.index, 0);
  });

  test('repeat all wraps in both directions; repeat cycles off -> all -> one -> off', () {
    final p = make()..setQueue(songs, start: 3);
    p.cycleRepeat();
    expect(p.repeat, LoopSetting.all);
    p.next();
    expect(p.index, 0);
    p.prev();
    expect(p.index, 3);
    p.cycleRepeat();
    expect(p.repeat, LoopSetting.one);
    p.cycleRepeat();
    expect(p.repeat, LoopSetting.off);
  });

  test('shuffle keeps the current track and what was already played, and restores order when off', () {
    final p = make()..setQueue(songs, start: 1);
    p.toggleShuffle();
    expect(p.shuffle, isTrue);
    expect(p.now?.videoId, 'b');
    expect(p.queue[p.index].videoId, 'b');
    expect(ids(p).first, 'a'); // already-played tracks stay put
    expect(ids(p).toSet(), {'a', 'b', 'c', 'd'});
    p.toggleShuffle();
    expect(ids(p), ['a', 'b', 'c', 'd']);
    expect(p.queue[p.index].videoId, 'b');
  });

  test('starting a queue while shuffled puts the chosen song first', () {
    final p = make()..toggleShuffle();
    p.setQueue(songs, start: 2);
    expect(p.index, 0);
    expect(p.queue.first.videoId, 'c');
    expect(ids(p).toSet(), {'a', 'b', 'c', 'd'});
  });

  test('playNext / addToQueue / remove / move keep the current index correct', () {
    final p = make()..setQueue(songs, start: 1);
    p.playNext(song('x'));
    expect(ids(p), ['a', 'b', 'x', 'c', 'd']);
    p.addToQueue(song('y'));
    expect(ids(p).last, 'y');
    p.removeFromQueue(0); // before current: index shifts down
    expect(p.now?.videoId, 'b');
    expect(p.queue[p.index].videoId, 'b');
    p.removeFromQueue(p.index); // removing the playing track is ignored
    expect(p.queue[p.index].videoId, 'b');
    final before = ids(p);
    p.moveInQueue(before.indexOf('d'), 0); // an upcoming track dragged above the current one
    expect(p.queue[p.index].videoId, 'b');
    expect(ids(p).first, 'd');
  });

  test('clearUpcoming leaves just the playing track', () {
    final p = make()..setQueue(songs, start: 1);
    p.clearUpcoming();
    expect(ids(p), ['b']);
    expect(p.index, 0);
  });

  test('a song with no playable stream reports unavailable, and offline when there is no internet', () async {
    final p = make()..setQueue(songs);
    await pumpEventQueue();
    expect(p.error, PlaybackError.unavailable);
    expect(p.paused, isTrue);
    expect(p.loading, isFalse);

    final offline = make(online: false)..setQueue(songs);
    await pumpEventQueue();
    expect(offline.error, PlaybackError.offline);
  });
}
