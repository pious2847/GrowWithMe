package com.growwithme.grow_with_me

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: upcoming care visits as chip-labelled rows plus the
 * daily feeding tip. Data is written by the Flutter side (WidgetService) via
 * home_widget's SharedPreferences bridge — fully offline.
 */
class ReminderWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_reminders)

            views.setTextViewText(
                R.id.widget_title,
                widgetData.getString("title", "") ?: ""
            )

            bindRow(
                views, widgetData, 1,
                R.id.row1, R.id.chip1, R.id.title1,
                emptyFallback = "Open GrowWithMe to set up your care calendar"
            )
            bindRow(views, widgetData, 2, R.id.row2, R.id.chip2, R.id.title2, null)
            bindRow(views, widgetData, 3, R.id.row3, R.id.chip3, R.id.title3, null)

            val tip = widgetData.getString("tip", "") ?: ""
            if (tip.isEmpty()) {
                views.setViewVisibility(R.id.widget_tip, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_tip, View.VISIBLE)
                views.setTextViewText(R.id.widget_tip, "🌿 $tip")
            }

            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindRow(
        views: RemoteViews,
        data: SharedPreferences,
        index: Int,
        rowId: Int,
        chipId: Int,
        titleId: Int,
        emptyFallback: String?
    ) {
        val whenText = data.getString("when$index", "") ?: ""
        val titleText = data.getString("title$index", "") ?: ""

        if (titleText.isEmpty()) {
            if (emptyFallback != null) {
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setViewVisibility(chipId, View.GONE)
                views.setTextViewText(titleId, emptyFallback)
            } else {
                views.setViewVisibility(rowId, View.GONE)
            }
            return
        }

        views.setViewVisibility(rowId, View.VISIBLE)
        views.setViewVisibility(chipId, View.VISIBLE)
        views.setTextViewText(chipId, whenText)
        views.setTextViewText(titleId, titleText)

        // "Today" (and overdue) chips get the filled brand style.
        if (whenText == "Today" || whenText == "Overdue") {
            views.setInt(chipId, "setBackgroundResource", R.drawable.chip_bg_today)
            views.setTextColor(chipId, Color.WHITE)
        } else {
            views.setInt(chipId, "setBackgroundResource", R.drawable.chip_bg)
            views.setTextColor(chipId, Color.parseColor("#1B5E20"))
        }
    }
}
