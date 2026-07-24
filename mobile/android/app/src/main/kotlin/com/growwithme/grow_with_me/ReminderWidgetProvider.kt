package com.growwithme.grow_with_me

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget, refreshed daily: mother-and-baby illustration with the
 * countdown to delivery (or the child's age), this week's checks, and the
 * daily motivation line.
 */
class ReminderWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            try {
                updateOne(context, appWidgetManager, widgetId, widgetData)
            } catch (_: Exception) {
                // A failed bind must never take down the whole widget host.
            }
        }
    }

    private fun updateOne(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_reminders)

        // Countdown computed at RENDER time from raw dates — the launcher
        // re-renders every 30 min, so this stays correct day after day even
        // if the app is never opened.
        val now = System.currentTimeMillis()
        val dayMs = 86_400_000L
        val edd = widgetData.getString("edd_millis", "")?.toLongOrNull()
        val dob = widgetData.getString("dob_millis", "")?.toLongOrNull()
        val childName = widgetData.getString("child_name", "") ?: ""
        var big: String
        var small: String
        if (edd != null && edd > 0) {
            val daysLeft = ((edd - now) / dayMs).toInt()
            if (daysLeft > 0) {
                big = "$daysLeft day" + (if (daysLeft == 1) "" else "s")
                small = "to delivery 🍼"
            } else {
                big = "Baby is due"
                small = "stay close to your clinic"
            }
        } else if (dob != null && dob > 0) {
            val days = ((now - dob) / dayMs).toInt()
            big = if (days < 60) "${days / 7} weeks" else "${days / 30} months"
            small = if (childName.isEmpty()) "growing strong 🌱"
                    else "$childName is growing 🌱"
        } else {
            big = widgetData.getString("countdown_big", "Welcome") ?: "Welcome"
            small = widgetData.getString("countdown_small", "to GrowWithMe") ?: ""
        }
        views.setTextViewText(R.id.countdown_big, big)
        views.setTextViewText(R.id.countdown_small, small)

        bindCheck(views, widgetData, 1, R.id.check1,
            fallback = "Open the app to plan your week")
        bindCheck(views, widgetData, 2, R.id.check2, fallback = null)
        bindCheck(views, widgetData, 3, R.id.check3, fallback = null)

        // Motivation rotates by day-of-year at render time.
        val motivationList = (widgetData.getString("motivations", "") ?: "")
            .split('|').filter { it.isNotBlank() }
        val motivation = if (motivationList.isNotEmpty()) {
            motivationList[java.time.LocalDate.now().dayOfYear % motivationList.size]
        } else {
            widgetData.getString("motivation", "") ?: ""
        }
        if (motivation.isEmpty()) {
            views.setViewVisibility(R.id.widget_motivation, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_motivation, View.VISIBLE)
            views.setTextViewText(R.id.widget_motivation, "🌟 $motivation")
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

    private fun bindCheck(
        views: RemoteViews,
        data: SharedPreferences,
        index: Int,
        viewId: Int,
        fallback: String?
    ) {
        val text = data.getString("check$index", "") ?: ""
        if (text.isEmpty()) {
            if (fallback != null) {
                views.setViewVisibility(viewId, View.VISIBLE)
                views.setTextViewText(viewId, fallback)
            } else {
                views.setViewVisibility(viewId, View.GONE)
            }
            return
        }
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, "○ $text")
    }
}
