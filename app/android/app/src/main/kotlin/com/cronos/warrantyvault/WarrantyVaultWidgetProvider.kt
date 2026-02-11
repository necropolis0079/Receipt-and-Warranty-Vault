package com.cronos.warrantyvault

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class WarrantyVaultWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val STATS_KEY = "stats_text"
        private const val DEFAULT_STATS = "0 receipts · 0 active warranties"

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val statsText = prefs.getString(STATS_KEY, DEFAULT_STATS) ?: DEFAULT_STATS

            val views = RemoteViews(context.packageName, R.layout.widget_warranty_vault)
            views.setTextViewText(R.id.widget_stats_text, statsText)

            // Camera button → deep-link to capture screen
            val captureIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("warrantyvault://capture?source=camera")
                setClassName(context.packageName, "com.cronos.warrantyvault.MainActivity")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val capturePendingIntent = PendingIntent.getActivity(
                context,
                1,
                captureIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_capture_button, capturePendingIntent)

            // Widget body → open app normally
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val launchPendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_body, launchPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
