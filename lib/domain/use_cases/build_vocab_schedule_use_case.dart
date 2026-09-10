import '../models/scheduled_vocab.dart';
import '../models/vocab.dart';

/// Builds the queue of terms to display over the coming hours.
///
/// This runs while the app is open and writes its result to shared storage.
/// The lock screen widget on iOS and the scheduled worker on Android then read
/// that queue on their own — no Dart code runs at display time, which is why
/// the schedule has to be computed ahead of time rather than one term at a
/// time.
class BuildVocabScheduleUseCase {
  const BuildVocabScheduleUseCase();

  /// Returns [count] entries starting at [from], spaced [interval] apart.
  ///
  /// Terms are ordered so the ones most in need of practice come first, and
  /// the list cycles once every term has had a turn.
  List<ScheduledVocab> call({
    required List<Vocab> vocabs,
    required Duration interval,
    required DateTime from,
    required int count,
  }) {
    if (vocabs.isEmpty || count <= 0) return const [];

    final ordered = [...vocabs]..sort(_byPracticeNeed);

    return List.generate(count, (index) {
      return ScheduledVocab(
        showAt: from.add(interval * index),
        vocab: ordered[index % ordered.length],
      );
    });
  }

  /// Never shown beats long ago, which beats recently shown. Ties fall back to
  /// the least practised term, then to the id so the result is reproducible.
  static int _byPracticeNeed(Vocab a, Vocab b) {
    final aShown = a.lastShownAt;
    final bShown = b.lastShownAt;

    if (aShown != bShown) {
      if (aShown == null) return -1;
      if (bShown == null) return 1;

      final byRecency = aShown.compareTo(bShown);
      if (byRecency != 0) return byRecency;
    }

    final byPractice = a.timesShown.compareTo(b.timesShown);
    if (byPractice != 0) return byPractice;

    return a.id.compareTo(b.id);
  }
}
