import 'vocab.dart';

/// One entry of the upcoming-terms queue: which term to display, and when.
///
/// The queue is handed to the native side ahead of time so iOS and Android can
/// rotate through it while the Flutter app is not running.
class ScheduledVocab {
  const ScheduledVocab({required this.showAt, required this.vocab});

  final DateTime showAt;
  final Vocab vocab;

  Map<String, Object?> toMap() => {
        'showAt': showAt.millisecondsSinceEpoch,
        'vocab': vocab.toMap(),
      };

  @override
  bool operator ==(Object other) =>
      other is ScheduledVocab && other.showAt == showAt && other.vocab == vocab;

  @override
  int get hashCode => Object.hash(showAt, vocab);

  @override
  String toString() => 'ScheduledVocab($showAt, ${vocab.term})';
}
