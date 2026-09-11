package com.example.lockscreen_learning_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.lockscreen_learning_app.R

/**
 * Draws the term whose slot is running right now.
 *
 * On a device new enough to place widgets on the lock screen this is the lock
 * screen widget too: Android has no separate API for that surface, and a home
 * screen widget appears there unless it opts out with the `not_keyguard`
 * category. So there is one provider, not two.
 */
class VocabWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // Read once for the whole batch. Every placed widget shows the same
        // term, so parsing the file per instance would only repeat the work.
        val current = ScheduleFile.read(context)?.currentAt(System.currentTimeMillis())
        val views = render(context, current)

        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    /**
     * Turns the current entry into what the launcher draws.
     *
     * A null entry is not an error state: before the first publish, and after
     * a queue has run out, there is genuinely nothing due — so it gets its own
     * wording rather than an empty box the user cannot interpret.
     *
     * TODO: this is scaffolding. The real layout, typography and the tap
     * target that opens the app belong here.
     */
    private fun render(context: Context, entry: PublishedEntry?): RemoteViews =
        RemoteViews(context.packageName, R.layout.vocab_widget).apply {
            setTextViewText(
                R.id.vocab_widget_term,
                entry?.term ?: context.getString(R.string.vocab_widget_empty_term),
            )
            setTextViewText(
                R.id.vocab_widget_translation,
                entry?.translation
                    ?: context.getString(R.string.vocab_widget_empty_translation),
            )
        }

    companion object {
        /**
         * Redraws every placed widget. Called from the method channel when the
         * app has just published a queue.
         *
         * Sent as a broadcast rather than by calling [onUpdate] directly: it
         * is the same path the system uses, and the same path an alarm will
         * use once the widget schedules its own slot changes — one way in is
         * easier to reason about than three.
         *
         * A device with no widget placed gets nothing, which is why the ids
         * are looked up rather than assumed.
         */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, VocabWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return

            context.sendBroadcast(
                Intent(context, VocabWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
            )
        }
    }
}
