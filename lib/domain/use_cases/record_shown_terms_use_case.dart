import '../models/published_schedule.dart';
import '../models/vocab.dart';

/// Works out which terms reached the lock screen while the app was closed.
///
/// Nothing native reports back yet, and on iOS nothing can: the widget draws
/// without running any code of ours. So this derives what happened instead of
/// being told — every entry of the last published queue whose moment has
/// passed did have its turn, because that queue is exactly what the lock
/// screen was working through.
///
/// Only slots that are completely over count. The term still on the lock
/// screen is left alone until its turn ends, so that merely opening the app
/// does not retire it early.
///
/// Each entry is counted once because publishing replaces the queue, and the
/// queue written after this runs never reaches back past the slot already
/// running.
class RecordShownTermsUseCase {
  const RecordShownTermsUseCase();

  /// The terms whose counts changed, already marked. Terms that had no turn
  /// are left out rather than returned unchanged, so the caller can save the
  /// result without checking what actually moved.
  List<Vocab> call({
    required PublishedSchedule? published,
    required List<Vocab> vocabs,
    required DateTime now,
  }) {
    if (published == null) return const [];

    final finished = published.finishedBy(now);
    if (finished.isEmpty) return const [];

    final stored = {for (final vocab in vocabs) vocab.id: vocab};
    final marked = <String, Vocab>{};

    // In order, earliest first, so the last mark applied to a term is the one
    // that dates it.
    for (final entry in finished) {
      final current = marked[entry.vocabId] ?? stored[entry.vocabId];

      // A term deleted since the queue was published has no count to keep.
      if (current == null) continue;

      marked[entry.vocabId] = current.markShown(entry.showAt);
    }

    return marked.values.toList();
  }
}
