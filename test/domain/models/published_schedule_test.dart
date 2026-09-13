import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:nagara/domain/models/published_schedule.dart';
import 'package:nagara/domain/models/scheduled_vocab.dart';
import 'package:nagara/domain/models/vocab.dart';

void main() {
  final nine = DateTime.utc(2026, 1, 1, 9);

  Vocab vocab(String id) => Vocab(
    id: id,
    deckId: 'd1',
    term: 'el libro',
    translation: 'das Buch',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final deck = Deck(
    id: 'd1',
    name: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: const Duration(hours: 3),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  PublishedSchedule schedule({List<ScheduledVocab>? upcoming}) =>
      PublishedSchedule.of(
        generatedAt: nine,
        deck: deck,
        upcoming:
            upcoming ?? [ScheduledVocab(showAt: nine, vocab: vocab('v1'))],
      );

  group('building from a schedule', () {
    test('takes the deck the entries were drawn from', () {
      final published = schedule();

      expect(published.deckId, 'd1');
      expect(published.deckName, 'Spanish basics');
      expect(published.sourceLanguage, 'es');
      expect(published.targetLanguage, 'de');
      expect(published.interval, const Duration(hours: 3));
    });

    test('reduces each term to what the lock screen draws', () {
      final entry = schedule().entries.single;

      expect(entry.showAt, nine);
      expect(entry.vocabId, 'v1');
      expect(entry.term, 'el libro');
      expect(entry.translation, 'das Buch');
    });

    test('keeps the entries in the order they are to be shown', () {
      final published = schedule(
        upcoming: [
          ScheduledVocab(showAt: nine, vocab: vocab('first')),
          ScheduledVocab(
            showAt: nine.add(const Duration(hours: 3)),
            vocab: vocab('second'),
          ),
        ],
      );

      expect(published.entries.map((e) => e.vocabId), ['first', 'second']);
    });
  });

  group('toJson', () {
    test('states its schema version, so a reader can refuse a payload it '
        'does not understand', () {
      expect(schedule().toJson()['schemaVersion'], PublishedSchedule.version);
    });

    test('writes every instant as epoch milliseconds, which every platform '
        'reads without agreeing on a date format', () {
      final json = schedule().toJson();
      final entries = json['entries']! as List<Object?>;

      expect(json['generatedAt'], nine.millisecondsSinceEpoch);
      expect(
        (entries.single! as Map<String, Object?>)['showAt'],
        nine.millisecondsSinceEpoch,
      );
    });
  });

  group('fromJson', () {
    test('reads back everything a round trip through a file puts in', () {
      final original = schedule(
        upcoming: [
          ScheduledVocab(showAt: nine, vocab: vocab('first')),
          ScheduledVocab(
            showAt: nine.add(const Duration(hours: 3)),
            vocab: vocab('second'),
          ),
        ],
      );

      final restored = PublishedSchedule.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, Object?>,
      );

      expect(restored.generatedAt, original.generatedAt);
      expect(restored.deckId, original.deckId);
      expect(restored.interval, original.interval);
      expect(restored.entries, original.entries);
    });

    test('refuses a payload from a version it does not know, rather than '
        'reading it wrong', () {
      final json = schedule().toJson()..['schemaVersion'] = 99;

      expect(
        () => PublishedSchedule.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('reading the running slot back', () {
    PublishedSchedule threeEntries() => schedule(
      upcoming: [
        ScheduledVocab(showAt: nine, vocab: vocab('first')),
        ScheduledVocab(
          showAt: nine.add(const Duration(hours: 3)),
          vocab: vocab('second'),
        ),
        ScheduledVocab(
          showAt: nine.add(const Duration(hours: 6)),
          vocab: vocab('third'),
        ),
      ],
    );

    group('currentAt', () {
      test('names the entry whose slot is running', () {
        final current = threeEntries().currentAt(
          nine.add(const Duration(hours: 1)),
        );

        expect(current!.vocabId, 'first');
      });

      test('moves on the moment the next slot starts', () {
        final current = threeEntries().currentAt(
          nine.add(const Duration(hours: 3)),
        );

        expect(current!.vocabId, 'second');
      });

      test('reports nothing once the queue has run out, so a rebuild starts '
          'afresh instead of in the past', () {
        expect(
          threeEntries().currentAt(nine.add(const Duration(days: 1))),
          isNull,
        );
      });

      test('reports nothing for a queue that has not started yet', () {
        expect(
          threeEntries().currentAt(nine.subtract(const Duration(hours: 1))),
          isNull,
        );
      });
    });

    group('finishedBy', () {
      test('leaves out the slot still running, which has not had its full '
          'turn', () {
        final finished = threeEntries().finishedBy(
          nine.add(const Duration(hours: 1)),
        );

        expect(finished, isEmpty);
      });

      test('counts a slot the moment the next one takes over', () {
        final finished = threeEntries().finishedBy(
          nine.add(const Duration(hours: 3)),
        );

        expect(finished.map((e) => e.vocabId), ['first']);
      });

      test('names them all once the whole queue is behind us', () {
        expect(
          threeEntries().finishedBy(nine.add(const Duration(days: 1))),
          hasLength(3),
        );
      });
    });
  });
}
