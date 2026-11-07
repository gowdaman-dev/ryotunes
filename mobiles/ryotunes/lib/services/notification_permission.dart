import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 13+ keeps the playback notification (and so the lock-screen controls) hidden until
/// notifications are allowed. Asks once per launch, the first time something plays.
class NotificationPermission {
  static const _channel = MethodChannel('dev.ryoku.ryotunes/permissions');
  static bool _asked = false;

  static Future<void> requestOnce() async {
    if (_asked) return;
    _asked = true;
    try {
      await _channel.invokeMethod<bool>('requestNotifications');
    } on MissingPluginException {
      // Not running on Android (or in a test): nothing to ask.
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }
}
