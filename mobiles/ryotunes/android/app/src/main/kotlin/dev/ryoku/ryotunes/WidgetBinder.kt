package dev.ryoku.ryotunes

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.view.KeyEvent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.io.File

/**
 * Fills a Ryotunes widget's views from the state the Flutter app saves (title, artist, artwork
 * path, playing flag) and wires its buttons to the player.
 *
 * Buttons send media-button key events to audio_service's receiver, so they control the running
 * player without starting Dart code in the background.
 */
object WidgetBinder {
    private const val MEDIA_RECEIVER = "com.ryanheise.audioservice.MediaButtonReceiver"

    fun bind(context: Context, views: RemoteViews, data: SharedPreferences, withPrev: Boolean) {
        val title = data.getString("widget_title", null)
        val artist = data.getString("widget_artist", null)
        val playing = data.getBoolean("widget_playing", false)
        val art = loadArt(data.getString("widget_art", null), 360)

        views.setTextViewText(R.id.widget_title, title ?: context.getString(R.string.widget_idle_title))
        views.setTextViewText(R.id.widget_artist, if (title == null) context.getString(R.string.widget_idle_subtitle) else artist ?: "")
        if (art != null) views.setImageViewBitmap(R.id.widget_art, art) else views.setImageViewResource(R.id.widget_art, R.mipmap.ic_launcher)
        views.setImageViewResource(R.id.widget_play, if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play)

        views.setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
        views.setOnClickPendingIntent(R.id.widget_play, mediaKey(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
        views.setOnClickPendingIntent(R.id.widget_next, mediaKey(context, KeyEvent.KEYCODE_MEDIA_NEXT))
        if (withPrev) views.setOnClickPendingIntent(R.id.widget_prev, mediaKey(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
    }

    private fun mediaKey(context: Context, keyCode: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            component = ComponentName(context, MEDIA_RECEIVER)
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        }
        return PendingIntent.getBroadcast(context, keyCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    /** Decode [path] at roughly [size] px with rounded corners; null if missing or unreadable. */
    private fun loadArt(path: String?, size: Int): Bitmap? {
        if (path.isNullOrEmpty() || !File(path).exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= size) sample *= 2
            val src = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample }) ?: return null
            val side = minOf(src.width, src.height)
            val square = Bitmap.createBitmap(src, (src.width - side) / 2, (src.height - side) / 2, side, side)
            val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = BitmapShader(Bitmap.createScaledBitmap(square, size, size, true), Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            }
            Canvas(out).drawRoundRect(RectF(0f, 0f, size.toFloat(), size.toFloat()), size * 0.16f, size * 0.16f, paint)
            out
        } catch (e: Exception) {
            null
        }
    }
}
