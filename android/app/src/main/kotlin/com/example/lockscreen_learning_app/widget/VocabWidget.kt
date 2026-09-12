package com.example.lockscreen_learning_app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import com.example.lockscreen_learning_app.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Draws the term whose slot is running right now.
 *
 * On a device new enough to place widgets on the lock screen this is the lock
 * screen widget too: Android has no separate API for that surface, and a home
 * screen widget appears there unless it opts out with the `not_keyguard`
 * category. So there is one widget, not two.
 */
class VocabWidget : GlanceAppWidget() {
    /**
     * Reads the queue once up front, then keeps reading it inside the
     * composition as [ScheduleRevision] moves.
     *
     * Both halves are needed and neither is redundant. The read before
     * `provideContent` is what Glance asks for — it means the first frame draws
     * the right term instead of flashing the empty state. The one inside is what
     * survives a refresh arriving while the session is still alive, which
     * [ScheduleRevision] explains.
     *
     * The first pass therefore reads twice, for a few kilobytes of JSON. Paying
     * that is cheaper than the bookkeeping it would take to skip it.
     */
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val initial = read(context)

        provideContent {
            val revision by ScheduleRevision.current.collectAsState()
            var current by remember { mutableStateOf(initial) }

            LaunchedEffect(revision) { current = read(context) }

            Content(
                term = current?.term
                    ?: context.getString(R.string.vocab_widget_empty_term),
                translation = current?.translation
                    ?: context.getString(R.string.vocab_widget_empty_translation),
            )
        }
    }

    /**
     * Glance already runs its work off the main thread, on Dispatchers.Default.
     * The hop is for the pool it would otherwise block: Default is sized for CPU
     * work, and a blocking file read parks one of its threads.
     */
    private suspend fun read(context: Context): PublishedEntry? =
        withContext(Dispatchers.IO) {
            ScheduleFile.read(context)?.currentAt(System.currentTimeMillis())
        }

    /**
     * A null entry is not an error state: before the first publish, and after a
     * queue has run out, there is genuinely nothing due — so the caller resolves
     * it to wording the user can act on rather than passing an empty box down.
     *
     * TODO: scaffolding, deliberately. Background, colour, type, spacing, the
     * size buckets and the tap target that opens the app all belong here, and
     * none of them are part of the move to Glance.
     */
    @Composable
    private fun Content(term: String, translation: String) {
        // The one layout call kept: Glance defaults to wrap-content, and a widget
        // that shrinks to its text reads as a bug rather than as undesigned.
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Text(term)
            Text(translation)
        }
    }
}
