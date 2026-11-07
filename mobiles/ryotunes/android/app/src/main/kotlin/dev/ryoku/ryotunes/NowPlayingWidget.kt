package dev.ryoku.ryotunes

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** 4x2 card: artwork, title, artist and previous / play-pause / next. */
class NowPlayingWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_now_playing)
            WidgetBinder.bind(context, views, widgetData, withPrev = true)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
