package com.github.quendo05.lockscreenvocab.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

/**
 * The system's way in. Owns nothing about how the widget looks.
 *
 * [GlanceAppWidgetReceiver] is still an `AppWidgetProvider`, so the manifest
 * entry, the `APPWIDGET_UPDATE` filter and `updatePeriodMillis` keep working
 * unchanged. What it adds is a `goAsync` scope around the update, which is what
 * lets [VocabWidget.provideGlance] suspend.
 */
class VocabWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = VocabWidget()

    companion object {
        /**
         * Redraws every placed widget. Called from the method channel when the
         * app has just published a queue.
         *
         * Still a broadcast rather than `VocabWidget().updateAll(context)`: it is
         * the same path the system uses, and the same path an alarm will use once
         * the widget schedules its own slot changes — one way in is easier to
         * reason about than three. `updateAll` also suspends, which would push a
         * coroutine scope into `MainActivity` for no gain, since the receiver's
         * own `goAsync` already keeps the process alive for the update.
         *
         * A device with no widget placed gets nothing from the broadcast, which
         * is why the ids are looked up rather than assumed.
         */
        fun refresh(context: Context) {
            // First, because a composition that is still on screen will not be
            // handed a fresh `provideGlance` by the broadcast below.
            ScheduleRevision.bump()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, VocabWidgetReceiver::class.java)
            )
            if (ids.isEmpty()) return

            context.sendBroadcast(
                Intent(context, VocabWidgetReceiver::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
            )
        }
    }
}
