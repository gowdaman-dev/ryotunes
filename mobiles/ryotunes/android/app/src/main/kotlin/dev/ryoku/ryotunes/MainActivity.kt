package dev.ryoku.ryotunes

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    // The Flutter engine hosts the player and queue logic. Keep it alive when the screen goes away
    // (swiped from recents, back out of the app) so music keeps playing and Next / Previous work.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Android 13+ hides the playback notification (lock-screen / shade controls) until the
        // user grants POST_NOTIFICATIONS, so the app asks for it the first time music plays.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.ryoku.ryotunes/permissions").setMethodCallHandler { call, result ->
            if (call.method != "requestNotifications") return@setMethodCallHandler result.notImplemented()
            val needed = Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
            if (needed) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4242)
            result.success(!needed)
        }
    }
}
