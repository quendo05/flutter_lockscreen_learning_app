import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/domain/models/published_schedule.dart';
import 'package:lockscreen_learning_app/domain/models/scheduled_vocab.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';

void main() {
  Vocab vocab(String id) => Vocab(
    id: id,
    deckId: 'd1',
    term: 'el libro',
    translation: 'das Buch',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  PublishedSchedule schedule({List<ScheduledVocab>? entries}) =>
      PublishedSchedule(
        generatedAt: DateTime.utc(2026, 1, 1, 9),
        deckId: 'd1',
        deckName: 'Spanish basics',
        sourceLanguage: 'es',
        targetLanguage: 'de',
        interval: const Duration(hours: 3),
        entries:
            entries ??
            [
              ScheduledVocab(
                showAt: DateTime.utc(2026, 1, 1, 9),
                vocab: vocab('v1'),
              ),
            ],
      );

  group('toJson', () {
    test('states its schema version, so the native reader can refuse a '
        'payload it does not understand', () {
      expect(schedule().toJson()['schemaVersion'], PublishedSchedule.version);
    });

    test('carries the deck the entries were drawn from', () {
      final json = schedule().toJson();

      expect(json['deckId'], 'd1');
      expect(json['deckName'], 'Spanish basics');
      expect(json['sourceLanguage'], 'es');
      expect(json['targetLanguage'], 'de');
    });

    test('writes every instant as epoch milliseconds, which every platform '
        'can read without parsing a date format', () {
      final json = schedule().toJson();
      final entries = json['entries']! as List<Object?>;

      expect(
        json['generatedAt'],
        DateTime.utc(2026, 1, 1, 9).millisecondsSinceEpoch,
      );
      expect(
        (entries.single! as Map<String, Object?>)['showAt'],
        DateTime.utc(2026, 1, 1, 9).millisecondsSinceEpoch,
      );
    });

    test('carries what the lock screen has to draw, and the id to report '
        'back', () {
      final entry =
          (schedule().toJson()['entries']! as List<Object?>).single!
              as Map<String, Object?>;

      expect(entry['vocabId'], 'v1');
      expect(entry['term'], 'el libro');
      expect(entry['translation'], 'das Buch');
    });

    test('keeps the entries in the order they are to be shown', () {
      final json = schedule(
        entries: [
          ScheduledVocab(
            showAt: DateTime.utc(2026, 1, 1, 9),
            vocab: vocab('first'),
          ),
          ScheduledVocab(
            showAt: DateTime.utc(2026, 1, 1, 12),
            vocab: vocab('second'),
          ),
        ],
      ).toJson();

      final ids = (json['entries']! as List<Object?>)
          .map((e) => (e! as Map<String, Object?>)['vocabId'])
          .toList();

      expect(ids, ['first', 'second']);
    });

    test('survives a round trip through JSON, which is how it is stored', () {
      expect(() => schedule().toJson(), returnsNormally);
    });
  });
}
