package com.example.lockscreen_learning_app.widget

import kotlinx.coroutines.flow.MutableStateFlow

/**
 * Tells a composition that is already on screen that a new queue was published.
 *
 * Glance keeps a widget's composition alive for roughly 45 seconds after it
 * first draws, and an update deliberately does not restart `provideGlance`
 * while that session lasts. A refresh landing inside that window would redraw
 * the term it already had — and that is this app's ordinary path, not an edge
 * case, because the app republishes both when it is opened and when it is left.
 *
 * So the composition watches this instead of reading the file once. A refresh
 * arriving after the session has ended starts a new one anyway, which is why
 * this only has to work in-process: a session can only be alive in the process
 * doing the publishing.
 */
internal object ScheduleRevision {
    val current = MutableStateFlow(0L)

    fun bump() {
        current.value += 1L
    }
}
