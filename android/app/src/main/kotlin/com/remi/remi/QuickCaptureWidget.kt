package com.remi.remi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuickCaptureWidget : HomeWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_capture_widget)
            
            // Get data from HomeWidget with defaults
            val tasks = widgetData.getInt("taskCount", 0)
            val memories = widgetData.getInt("memoryCount", 0)
            val latestMemory = widgetData.getString("latest_memory", null)
            
            // Set the title
            views.setTextViewText(R.id.widget_title, "REMI")
            
            // Set memory text or default placeholder
            val displayText = if (latestMemory.isNullOrBlank()) {
                "Tippe zum Aufnehmen..."
            } else {
                if (latestMemory.length > 60) {
                    "${latestMemory.take(57)}..."
                } else {
                    latestMemory
                }
            }
            views.setTextViewText(R.id.widget_memory_text, displayText)
            
            // Create intent for quick record action
            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("remi://quick-record")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("widgetClick", true)
            }
            
            // Create PendingIntent with proper flags for Android 12+
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context, 
                appWidgetId, 
                intent, 
                pendingIntentFlags
            )
            
            views.setOnClickPendingIntent(R.id.btn_quick_capture, pendingIntent)
            
            // Also make the whole widget clickable
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Called when the first widget is created
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Called when the last widget is removed
    }
}
