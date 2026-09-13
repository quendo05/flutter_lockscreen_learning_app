package com.github.quendo05.nagara.widget

import org.json.JSONObject

/**
 * One entry of the published queue: what to draw, and when.
 *
 * Mirrors `PublishedEntry` in `lib/domain/models/published_schedule.dart`.
 * There is no compiler between the two, so a field changed on one side is a
 * field that has to change on this one — [PublishedSchedule.VERSION] is what
 * catches it when that is forgotten.
 */
data class PublishedEntry(
    val showAtMillis: Long,
    val vocabId: String,
    val term: String,
    val translation: String,
)

/**
 * The queue of upcoming terms, as the Flutter app leaves it behind.
 *
 * Read without any Dart running: everything the widget has to draw is already
 * in here, because there is nothing to call back to.
 */
data class PublishedSchedule(
    val generatedAtMillis: Long,
    val deckId: String,
    val deckName: String,
    val sourceLanguage: String,
    val targetLanguage: String,
    val intervalMillis: Long,
    /** Ordered by [PublishedEntry.showAtMillis], earliest first. */
    val entries: List<PublishedEntry>,
) {
    /**
     * The entry that should be on screen at [nowMillis], or null when the
     * queue does not cover that moment — it lies wholly in the future, or it
     * ran out while the app was away.
     *
     * Android has no timeline to hand the system the way WidgetKit does, so
     * the widget answers this itself every time it redraws. That is also what
     * makes it drift-tolerant: an update that arrives four minutes late still
     * renders the term whose slot is running, not the one after it.
     */
    fun currentAt(nowMillis: Long): PublishedEntry? {
        for (entry in entries.asReversed()) {
            if (entry.showAtMillis > nowMillis) continue

            // The last entry that has started. Whether its slot is still
            // running decides whether the queue reaches [nowMillis] at all.
            return if (nowMillis < entry.showAtMillis + intervalMillis) entry else null
        }

        return null
    }

    companion object {
        /**
         * The payload shape this build understands.
         *
         * Must match `PublishedSchedule.version` on the Dart side. A payload
         * written by a newer app is refused rather than guessed at, which is
         * the whole point of carrying it.
         */
        const val VERSION = 1

        /**
         * Reads a payload, or returns null if it is not one this build can use.
         *
         * Null rather than a throw, because there is nobody here to tell. A
         * widget renders its empty state and waits for the next write — the
         * same thing it does before the app has ever published anything.
         */
        fun fromJson(raw: String): PublishedSchedule? = try {
            val json = JSONObject(raw)
            if (json.getInt("schemaVersion") != VERSION) null else read(json)
        } catch (error: Exception) {
            null
        }

        private fun read(json: JSONObject): PublishedSchedule {
            val array = json.getJSONArray("entries")
            val entries = ArrayList<PublishedEntry>(array.length())
            for (index in 0 until array.length()) {
                val entry = array.getJSONObject(index)
                entries.add(
                    PublishedEntry(
                        showAtMillis = entry.getLong("showAt"),
                        vocabId = entry.getString("vocabId"),
                        term = entry.getString("term"),
                        translation = entry.getString("translation"),
                    )
                )
            }

            return PublishedSchedule(
                generatedAtMillis = json.getLong("generatedAt"),
                deckId = json.getString("deckId"),
                deckName = json.getString("deckName"),
                sourceLanguage = json.getString("sourceLanguage"),
                targetLanguage = json.getString("targetLanguage"),
                // Minutes on the wire, because that is the unit a deck's
                // display interval is stored in; milliseconds here, because
                // that is what every Android clock deals in.
                intervalMillis = json.getLong("intervalMinutes") * 60_000L,
                entries = entries,
            )
        }
    }
}
