package com.github.quendo05.nagara.widget

import android.content.Context
import java.io.File

/**
 * Where the Flutter app leaves the queue, and the only place that knows it.
 *
 * The app writes this through `getApplicationSupportDirectory()`, which maps
 * to [Context.getFilesDir] on Android. No permission and no content provider
 * is involved: an app widget's provider runs inside the app's own process, so
 * it reads the private file directly.
 *
 * The app writes to a neighbour and renames over this path, and rename is
 * atomic, so a read landing mid-write sees the previous queue rather than half
 * of the new one. Nothing here has to lock.
 */
internal object ScheduleFile {
    private const val NAME = "schedule.json"

    /** The published queue, or null when there is none to be had. */
    fun read(context: Context): PublishedSchedule? {
        val file = File(context.filesDir, NAME)
        if (!file.exists()) return null

        return try {
            PublishedSchedule.fromJson(file.readText())
        } catch (error: Exception) {
            // An unreadable file is treated as an absent one, for the same
            // reason an unparseable payload is: the next write replaces it
            // either way, and a widget has no better move than its empty state.
            null
        }
    }
}
