import 'package:flutter/material.dart';
import 'app.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initAudioService();
  } catch (e, st) {
    debugPrint('AudioService init failed: $e\n$st');
  }
  runApp(const RyotunesApp());
}