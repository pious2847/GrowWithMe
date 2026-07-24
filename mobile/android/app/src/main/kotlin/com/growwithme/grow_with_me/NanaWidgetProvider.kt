package com.growwithme.grow_with_me

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Nana says" widget: the daily message from the AI care educator. Tapping it
 * opens the app straight into Nana, who reads the day's briefing aloud —
 * voice-first care for caregivers who cannot read.
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
                val views = RemoteViews(context.packageName, R.layout.widget_nana).apply {
                    setTextViewText(
                        R.id.nana_date,
                        widgetData.getString("nana_date", "") ?: ""
                    )
                    setTextViewText(
                        R.id.nana_message,
                        widgetData.getString(
                            "nana_message",
                            "Hello! Open GrowWithMe and I will help you care for your family."
                        )
                    )
                }

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
