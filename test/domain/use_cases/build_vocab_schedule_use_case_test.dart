import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/domain/use_cases/build_vocab_schedule_use_case.dart';

void main() {
  final from = DateTime.utc(2026, 5, 1, 8, 0);
  const interval = Duration(hours: 3);
  const useCase = BuildVocabScheduleUseCase();

  Vocab vocab(String id, {DateTime? lastShownAt, int timesShown = 0}) => Vocab(
    id: id,
    deckId: 'd1',
    term: 'term-$id',
    translation: 'translation-$id',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    createdAt: DateTime.utc(2026, 1, 1),
    lastShownAt: lastShownAt,
    timesShown: timesShown,
  );

  group('empty results', () {
    test('returns nothing when there are no vocabulary entries', () {
      final schedule = useCase(
        vocabs: const [],
        interval: interval,
        from: from,
        count: 5,
      );

      expect(schedule, isEmpty);
    });

    test('returns nothing when zero entries are requested', () {
      final schedule = useCase(
        vocabs: [vocab('a')],
        interval: interval,
        from: from,
        count: 0,
      );

      expect(schedule, isEmpty);
    });
  });

  group('timing', () {
    test('schedules the first term at the starting moment itself', () {
      final schedule = useCase(
        vocabs: [vocab('a')],
        interval: interval,
        from: from,
        count: 1,
      );

      expect(schedule.single.showAt, from);
    });

    test('spaces consecutive terms one interval apart', () {
      final schedule = useCase(
        vocabs: [vocab('a'), vocab('b'), vocab('c')],
        interval: interval,
        from: from,
        count: 3,
      );

      expect(schedule.map((e) => e.showAt).toList(), [
        from,
        from.add(interval),
        from.add(interval * 2),
      ]);
    });

    test('produces exactly the requested number of entries', () {
      final schedule = useCase(
        vocabs: [vocab('a'), vocab('b')],
        interval: interval,
        from: from,
        count: 7,
      );

      expect(schedule, hasLength(7));
    });
  });

  group('selection order', () {
    test('shows never-seen terms before terms already shown', () {
      final schedule = useCase(
        vocabs: [
          vocab('seen', lastShownAt: DateTime.utc(2026, 4, 30), timesShown: 1),
          vocab('fresh'),
        ],
        interval: interval,
        from: from,
        count: 2,
      );

      expect(schedule.map((e) => e.vocab.id).toList(), ['fresh', 'seen']);
    });

    test('shows the least recently seen term first among seen terms', () {
      final schedule = useCase(
        vocabs: [
          vocab(
            'recent',
            lastShownAt: DateTime.utc(2026, 4, 30),
            timesShown: 1,
          ),
          vocab('stale', lastShownAt: DateTime.utc(2026, 1, 5), timesShown: 1),
        ],
        interval: interval,
        from: from,
        count: 2,
      );

      expect(schedule.map((e) => e.vocab.id).toList(), ['stale', 'recent']);
    });

    test('prefers the least practised term when neither has been seen', () {
      final schedule = useCase(
        vocabs: [vocab('drilled', timesShown: 9), vocab('rare', timesShown: 2)],
        interval: interval,
        from: from,
        count: 2,
      );

      expect(schedule.map((e) => e.vocab.id).toList(), ['rare', 'drilled']);
    });

    test('breaks remaining ties by id so the order is reproducible', () {
      final schedule = useCase(
        vocabs: [vocab('b'), vocab('a')],
        interval: interval,
        from: from,
        count: 2,
      );

      expect(schedule.map((e) => e.vocab.id).toList(), ['a', 'b']);
    });
  });

  group('cycling', () {
    test('starts over from the first term once every term has been used', () {
      final schedule = useCase(
        vocabs: [vocab('a'), vocab('b')],
        interval: interval,
        from: from,
        count: 5,
      );

      expect(schedule.map((e) => e.vocab.id).toList(), [
        'a',
        'b',
        'a',
        'b',
        'a',
      ]);
    });
  });

  test('does not modify the list it was given', () {
    final vocabs = [vocab('b'), vocab('a')];

    useCase(vocabs: vocabs, interval: interval, from: from, count: 2);

    expect(vocabs.map((v) => v.id).toList(), ['b', 'a']);
  });
}
