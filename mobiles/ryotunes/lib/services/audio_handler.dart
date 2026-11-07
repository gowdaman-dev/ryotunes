import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

RyotunesAudioHandler? audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => RyotunesAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'dev.ryoku.ryotunes.channel.audio',
      androidNotificationChannelName: 'Ryotunes playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
}

class RyotunesAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();
  SongItem? currentSong;
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;

  RyotunesAudioHandler() {
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> loadSong(SongItem song, String url, {Map<String, String>? headers}) async {
    currentSong = song;
    final item = MediaItem(
      id: url,
      title: song.title,
      artist: song.artists,
      album: song.album,
      duration: song.duration != null ? _parseDur(song.duration!) : null,
      artUri: song.thumbnail != null ? Uri.tryParse(song.thumbnail!) : null,
    );
    mediaItem.add(item);
    await player.setUrl(url, headers: headers);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPrevious?.call();

  Duration? _parseDur(String d) {
    final parts = d.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: m, seconds: s);
    }
    return null;
  }
}