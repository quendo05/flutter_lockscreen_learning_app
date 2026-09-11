import 'scheduled_vocab.dart';

/// The queue of upcoming terms as the native side receives it.
///
/// This is the contract between the Flutter app and the lock screen: the app
/// writes one of these whenever it knows something new, and the widget reads
/// it without any Dart running. Everything the widget has to draw is therefore
/// already in here — it cannot call back to ask.
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

  /// The shape of [toJson].
  ///
  /// Written into every payload so a widget built against an older shape can
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

  /// Ordered by [ScheduledVocab.showAt], earliest first.
  final List<ScheduledVocab> entries;

  Map<String, Object?> toJson() => {
    'schemaVersion': version,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
    'deckId': deckId,
    'deckName': deckName,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'intervalMinutes': interval.inMinutes,
    'entries': [
      for (final entry in entries)
        {
          'showAt': entry.showAt.millisecondsSinceEpoch,
          // The id is what the app matches on when it works out which entries
          // have already had their turn.
          'vocabId': entry.vocab.id,
          'term': entry.vocab.term,
          'translation': entry.vocab.translation,
        },
    ],
  };
}
