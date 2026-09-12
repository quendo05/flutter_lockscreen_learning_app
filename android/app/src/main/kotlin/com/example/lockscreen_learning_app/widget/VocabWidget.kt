package com.example.lockscreen_learning_app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.lockscreen_learning_app.MainActivity
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
     * Five buckets rather than [SizeMode.Exact], which would recompose for every
     * pixel the user drags, and rather than the two this started with, which
     * left a widget dragged wide showing the same small type it used in a single
     * row.
     *
     * The heights are a contract, not a hint: Glance lays the composition out
     * against the bucket it picks, so content taller than the bucket is clipped
     * however much room the widget actually has. Each one is therefore set above
     * what [metricsFor] measures at its own type sizes, and the slack is the
     * margin for a user who has turned font scaling up.
     */
    override val sizeMode = SizeMode.Responsive(setOf(TINY, SMALL, MEDIUM, LARGE, HUGE))

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
            var entry by remember { mutableStateOf(initial) }

            LaunchedEffect(revision) { entry = read(context) }

            Panel(context, entry)
        }
    }

    /**
     * Glance already runs its work off the main thread, on Dispatchers.Default.
     * The hop is for the pool it would otherwise block: Default is sized for CPU
     * work, and a blocking file read parks one of its threads.
     */
    private suspend fun read(context: Context): PublishedEntry? = withContext(Dispatchers.IO) {
        ScheduleFile.read(context)?.currentAt(System.currentTimeMillis())
    }

    /**
     * The panel: the term, and its translation under it.
     *
     * Nothing else. The deck name and the language pair were both here and both
     * went: on the one surface where the user has a second to spare, a label
     * they already know costs the room that makes the term readable.
     *
     * An empty queue is not an error and is deliberately not drawn as one:
     * before the first publish and after a queue runs out there is genuinely
     * nothing due, so the slots stay where they are and only the wording and the
     * colour change. A layout that collapsed instead would make "nothing due"
     * look like a broken widget.
     */
    @Composable
    private fun Panel(context: Context, entry: PublishedEntry?) {
        val metrics = metricsFor(LocalSize.current)

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                // appWidgetBackground marks this as the view the launcher may
                // round-clip on Android 12+. The drawable carries the shape
                // itself as well, so the corners survive on older releases.
                .appWidgetBackground()
                .background(
                    ImageProvider(R.drawable.widget_surface),
                    contentScale = ContentScale.FillBounds,
                )
                .padding(
                    horizontal = metrics.horizontalPadding,
                    vertical = metrics.verticalPadding,
                )
                .clickable(actionStartActivity<MainActivity>())
                // One description for the whole panel. Left to itself TalkBack
                // reads the two lines as unrelated fragments.
                .semantics { contentDescription = describe(context, entry) },
            // Centred rather than pinned to the top, because the composition is
            // laid out for the bucket but stretched to the real size: anything
            // anchored to an edge drifts as the user drags, and the middle is
            // the one place that stays put.
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            Text(
                text = entry?.term ?: context.getString(R.string.vocab_widget_empty_term),
                maxLines = 1,
                style = TextStyle(
                    // Bold, where the app's own card uses a regular headline.
                    // That card sits on a colour the app picked; this sits on a
                    // wallpaper the app has never seen.
                    fontSize = metrics.termSize,
                    fontWeight = FontWeight.Bold,
                    // Muted when nothing is due, so the slot reads as a prompt
                    // rather than as a term called "No term due".
                    color = ColorProvider(
                        if (entry == null) {
                            R.color.widget_on_surface_variant
                        } else {
                            R.color.widget_on_surface
                        },
                    ),
                ),
            )

            Spacer(GlanceModifier.height(metrics.gap))

            Text(
                text = entry?.translation
                    ?: context.getString(R.string.vocab_widget_empty_translation),
                maxLines = metrics.translationLines,
                style = TextStyle(
                    fontSize = metrics.translationSize,
                    color = ColorProvider(R.color.widget_on_surface_variant),
                ),
            )
        }
    }

    private companion object {
        /** Squashed to a single row: the two lines and almost no margin. */
        val TINY = DpSize(110.dp, 48.dp)

        /** One comfortable row. */
        val SMALL = DpSize(160.dp, 64.dp)

        /** Two rows, which is what a default placement gets. */
        val MEDIUM = DpSize(220.dp, 88.dp)

        /** Dragged out deliberately — type grows to match rather than floating. */
        val LARGE = DpSize(260.dp, 134.dp)

        /**
         * A panel given most of a screen row. Worth its own step because the
         * composition is laid out for the bucket and then stretched to the real
         * size: without it a widget twice this tall still draws the type LARGE
         * chose, and the term floats in a field of nothing.
         */
        val HUGE = DpSize(300.dp, 180.dp)

        /**
         * Type and spacing for the bucket in play.
         *
         * Keyed on height alone. Width decides how much of a long term survives
         * before it ellipsizes, which the layout handles on its own; height is
         * the dimension that decides what fits at all.
         *
         * The measured content heights, for anyone changing these: roughly 42dp
         * tiny, 54dp small, 72dp medium, 122dp large and 150dp huge, each
         * comfortably inside its bucket above.
         */
        fun metricsFor(size: DpSize): Metrics = when {
            size.height >= HUGE.height -> Metrics(
                termSize = 38.sp,
                translationSize = 20.sp,
                translationLines = 2,
                horizontalPadding = 26.dp,
                verticalPadding = 22.dp,
                gap = 6.dp,
            )

            size.height >= LARGE.height -> Metrics(
                termSize = 30.sp,
                translationSize = 17.sp,
                // Two lines only here. Below this the second line is what pushes
                // the block past its bucket.
                translationLines = 2,
                horizontalPadding = 22.dp,
                verticalPadding = 18.dp,
                gap = 4.dp,
            )

            size.height >= MEDIUM.height -> Metrics(
                termSize = 22.sp,
                translationSize = 14.sp,
                translationLines = 1,
                horizontalPadding = 16.dp,
                verticalPadding = 12.dp,
                gap = 2.dp,
            )

            size.height >= SMALL.height -> Metrics(
                termSize = 17.sp,
                translationSize = 12.sp,
                translationLines = 1,
                horizontalPadding = 12.dp,
                verticalPadding = 8.dp,
                gap = 1.dp,
            )

            else -> Metrics(
                termSize = 14.sp,
                translationSize = 11.sp,
                translationLines = 1,
                horizontalPadding = 10.dp,
                verticalPadding = 5.dp,
                gap = 0.dp,
            )
        }
    }
}

/** What one size bucket draws with. */
private data class Metrics(
    val termSize: TextUnit,
    val translationSize: TextUnit,
    val translationLines: Int,
    val horizontalPadding: Dp,
    val verticalPadding: Dp,
    val gap: Dp,
)

private fun describe(context: Context, entry: PublishedEntry?): String = entry?.let {
    context.getString(R.string.vocab_widget_description_format, it.term, it.translation)
} ?: context.getString(R.string.vocab_widget_empty_description)
