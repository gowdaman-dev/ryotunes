import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class UserPlaylist {
  final String id;
  String name;
  final List<SongItem> songs;
  UserPlaylist({required this.id, required this.name, List<SongItem>? songs}) : songs = songs ?? [];

  String? get cover => songs.isEmpty ? null : songs.first.thumbnail;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'songs': songs.map((s) => s.toJson()).toList()};

  factory UserPlaylist.fromJson(Map<String, dynamic> j) => UserPlaylist(
        id: j['id'] as String,
        name: j['name'] as String,
        songs: ((j['songs'] as List?) ?? const []).map((e) => SongItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// The user's own data: playlists they create, liked songs and recently played. Stored on-device.
class LibraryController extends ChangeNotifier {
  static const likedId = 'liked';
  static const _key = 'library.v1';
  static const _recentLimit = 30;

  final List<UserPlaylist> _playlists = [UserPlaylist(id: likedId, name: 'Liked Songs')];
  final List<SongItem> _recent = [];

  /// Liked Songs first, then the user's playlists in creation order.
  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);
  List<SongItem> get recent => List.unmodifiable(_recent);
  UserPlaylist get liked => _playlists.first;

  UserPlaylist? byId(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool isLiked(String videoId) => liked.songs.any((s) => s.videoId == videoId);

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final saved = ((data['playlists'] as List?) ?? const []).map((e) => UserPlaylist.fromJson(e as Map<String, dynamic>)).toList();
      _playlists
        ..clear()
        ..addAll(saved);
      if (_playlists.isEmpty || _playlists.first.id != likedId) {
        _playlists.removeWhere((p) => p.id == likedId);
        _playlists.insert(0, UserPlaylist(id: likedId, name: 'Liked Songs'));
      }
      _recent
        ..clear()
        ..addAll(((data['recent'] as List?) ?? const []).map((e) => SongItem.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      debugPrint('Library load failed: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({'playlists': _playlists.map((p) => p.toJson()).toList(), 'recent': _recent.map((s) => s.toJson()).toList()}));
    } catch (e) {
      debugPrint('Library save failed: $e');
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  UserPlaylist create(String name, {SongItem? firstSong}) {
    final p = UserPlaylist(id: 'pl_${DateTime.now().microsecondsSinceEpoch}', name: name.trim(), songs: firstSong == null ? null : [firstSong]);
    _playlists.add(p);
    _changed();
    return p;
  }

  void rename(String id, String name) {
    final p = byId(id);
    if (p == null || id == likedId || name.trim().isEmpty) return;
    p.name = name.trim();
    _changed();
  }

  void delete(String id) {
    if (id == likedId) return;
    _playlists.removeWhere((p) => p.id == id);
    _changed();
  }

  /// Returns false when the song was already in the playlist.
  bool addSong(String playlistId, SongItem song) {
    final p = byId(playlistId);
    if (p == null || p.songs.any((s) => s.videoId == song.videoId)) return false;
    p.songs.add(song);
    _changed();
    return true;
  }

  void removeSong(String playlistId, String videoId) {
    byId(playlistId)?.songs.removeWhere((s) => s.videoId == videoId);
    _changed();
  }

  void toggleLike(SongItem song) {
    if (isLiked(song.videoId)) {
      liked.songs.removeWhere((s) => s.videoId == song.videoId);
    } else {
      liked.songs.insert(0, song);
    }
    _changed();
  }

  void addRecent(SongItem song) {
    _recent.removeWhere((s) => s.videoId == song.videoId);
    _recent.insert(0, song);
    if (_recent.length > _recentLimit) _recent.removeRange(_recentLimit, _recent.length);
    _changed();
  }
}
