package com.growwithme.grow_with_me

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Minimal Nana strip: one short line from her, matching the app's light
 * widget style. Tapping opens the app and Nana speaks the day's briefing —
 * voice-first care in a single sleek row.
 */
class NanaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_nana)

                val short = widgetData.getString("nana_short", "") ?: ""
                val long = widgetData.getString("nana_message", "") ?: ""
                views.setTextViewText(
                    R.id.nana_message,
                    when {
                        short.isNotEmpty() -> short
                        long.isNotEmpty() -> long
                        else -> "Hello! Open GrowWithMe and I will help you today."
                    }
                )

                val pending = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("growwithme://nana-briefing")
                )
                views.setOnClickPendingIntent(R.id.nana_root, pending)

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (_: Exception) {
                // Never take down the widget host.
            }
        }
    }
}
