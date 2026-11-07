package dev.ryoku.ryotunes

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** 4x1 slim bar: artwork, song and play-pause / next. */
class CompactWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_compact)
            WidgetBinder.bind(context, views, widgetData, withPrev = false)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
