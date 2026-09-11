import 'deck.dart';
import 'scheduled_vocab.dart';

/// One entry of a published queue: what to draw, and when.
///
/// Deliberately not a [ScheduledVocab]. That carries a whole [Vocab], most of
/// which the lock screen has no use for, and the payload has to survive a
/// round trip through JSON — which a full term, with its deck and its
/// timestamps, would not do without inventing fields nobody reads.
class PublishedEntry {
  const PublishedEntry({
    required this.showAt,
    required this.vocabId,
    required this.term,
    required this.translation,
  });

  /// Reduces a scheduled term to what the lock screen actually draws.
  factory PublishedEntry.of(ScheduledVocab scheduled) => PublishedEntry(
    showAt: scheduled.showAt,
    vocabId: scheduled.vocab.id,
    term: scheduled.vocab.term,
    translation: scheduled.vocab.translation,
  );

  final DateTime showAt;

  /// Which term this was. Kept so the app can work out, on its next run,
  /// which entries have already had their turn.
  final String vocabId;

  final String term;
  final String translation;

  Map<String, Object?> toJson() => {
    'showAt': showAt.millisecondsSinceEpoch,
    'vocabId': vocabId,
    'term': term,
    'translation': translation,
  };

  factory PublishedEntry.fromJson(Map<String, Object?> json) => PublishedEntry(
    showAt: DateTime.fromMillisecondsSinceEpoch(
      json['showAt']! as int,
      isUtc: true,
    ),
    vocabId: json['vocabId']! as String,
    term: json['term']! as String,
    translation: json['translation']! as String,
  );

  @override
  bool operator ==(Object other) =>
      other is PublishedEntry &&
      other.showAt == showAt &&
      other.vocabId == vocabId &&
      other.term == term &&
      other.translation == translation;

  @override
  int get hashCode => Object.hash(showAt, vocabId, term, translation);

  @override
  String toString() => 'PublishedEntry($showAt, $vocabId)';
}

/// The queue of upcoming terms as the native side receives it.
///
/// This is the contract between the Flutter app and the lock screen: the app
/// writes one of these whenever it knows something new, and the widget reads
/// it without any Dart running. Everything the widget has to draw is therefore
/// already in here — it cannot call back to ask.
///
/// The app reads it back too, to work out which entries have had their turn
/// since it last ran.
///
/// Instants are epoch milliseconds rather than formatted dates, because both
/// platforms read that without agreeing on a date format first.
class PublishedSchedule {
  const PublishedSchedule({
    required this.generatedAt,
    required this.deckId,
    required this.deckName,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.interval,
    required this.entries,
  });

  /// Builds a payload from a freshly computed schedule.
  factory PublishedSchedule.of({
    required DateTime generatedAt,
    required Deck deck,
    required List<ScheduledVocab> upcoming,
  }) => PublishedSchedule(
    generatedAt: generatedAt,
    deckId: deck.id,
    deckName: deck.name,
    sourceLanguage: deck.sourceLanguage,
    targetLanguage: deck.targetLanguage,
    interval: deck.displayInterval,
    entries: upcoming.map(PublishedEntry.of).toList(),
  );

  /// The shape of [toJson].
  ///
  /// Written into every payload so a reader built against an older shape can
  /// refuse one it does not understand instead of misreading it. Bump this
  /// whenever a field changes meaning or disappears.
  static const version = 1;

  /// When the app last worked the queue out. A widget can use this to tell a
  /// stale queue from a current one.
  final DateTime generatedAt;

  final String deckId;
  final String deckName;
  final String sourceLanguage;
  final String targetLanguage;

  /// The gap between two consecutive entries, repeated here so the widget does
  /// not have to derive it from the timestamps.
  final Duration interval;

  /// Ordered by [PublishedEntry.showAt], earliest first.
  final List<PublishedEntry> entries;

  /// The entry the lock screen is showing at [now], or null when the queue
  /// does not cover that moment.
  ///
  /// Null means there is nothing to carry on from: either the queue lies
  /// wholly in the future, or it ran out while the app was away.
  PublishedEntry? currentAt(DateTime now) {
    for (final entry in entries.reversed) {
      if (entry.showAt.isAfter(now)) continue;

      // The last entry that has started. Whether it is still running decides
      // whether the queue reaches [now] at all.
      return now.isBefore(entry.showAt.add(interval)) ? entry : null;
    }

    return null;
  }

  /// The entries whose slot is completely over by [now].
  ///
  /// The entry still showing is deliberately not among them. It is having its
  /// turn, not finished with it — counting it now would cut that turn short,
  /// because a term counted as shown falls behind in the next queue.
  List<PublishedEntry> finishedBy(DateTime now) => entries
      .where((entry) => !entry.showAt.add(interval).isAfter(now))
      .toList();

  Map<String, Object?> toJson() => {
    'schemaVersion': version,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
    'deckId': deckId,
    'deckName': deckName,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'intervalMinutes': interval.inMinutes,
    'entries': [for (final entry in entries) entry.toJson()],
  };

  /// Reads a payload back, or throws if it is not one.
  ///
  /// A payload from a newer app than this one is refused rather than guessed
  /// at — the whole point of [version].
  factory PublishedSchedule.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != version) {
      throw FormatException('Unsupported schedule version: $schemaVersion');
    }

    return PublishedSchedule(
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['generatedAt']! as int,
        isUtc: true,
      ),
      deckId: json['deckId']! as String,
      deckName: json['deckName']! as String,
      sourceLanguage: json['sourceLanguage']! as String,
      targetLanguage: json['targetLanguage']! as String,
      interval: Duration(minutes: json['intervalMinutes']! as int),
      entries: [
        for (final entry in json['entries']! as List<Object?>)
          PublishedEntry.fromJson(entry! as Map<String, Object?>),
      ],
    );
  }
}
