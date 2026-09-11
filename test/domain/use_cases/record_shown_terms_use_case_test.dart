import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/domain/models/published_schedule.dart';
import 'package:lockscreen_learning_app/domain/models/scheduled_vocab.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/domain/use_cases/record_shown_terms_use_case.dart';

void main() {
  const recordShown = RecordShownTermsUseCase();

  final nine = DateTime.utc(2026, 1, 1, 9);
  const threeHours = Duration(hours: 3);

  final deck = Deck(
    id: 'd1',
    name: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: threeHours,
    createdAt: DateTime.utc(2026, 1, 1),
  );

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

  /// A queue starting at nine, one entry per [threeHours], cycling through
  /// [ids] the way the scheduler does.
  PublishedSchedule published(List<String> ids) => PublishedSchedule.of(
    generatedAt: nine,
    deck: deck,
    upcoming: [
      for (var i = 0; i < ids.length; i++)
        ScheduledVocab(showAt: nine.add(threeHours * i), vocab: vocab(ids[i])),
    ],
  );

  test('records nothing when no queue was ever published', () {
    final updated = recordShown(
      published: null,
      vocabs: [vocab('a')],
      now: nine.add(const Duration(days: 1)),
    );

    expect(updated, isEmpty);
  });

  test('records nothing while the first entry is still showing', () {
    final updated = recordShown(
      published: published(['a', 'b']),
      vocabs: [vocab('a'), vocab('b')],
      now: nine,
    );

    expect(updated, isEmpty);
  });

  test('marks a term whose turn has passed', () {
    final updated = recordShown(
      published: published(['a', 'b']),
      vocabs: [vocab('a'), vocab('b')],
      now: nine.add(const Duration(hours: 1)),
    );

    expect(updated.single.id, 'a');
    expect(updated.single.timesShown, 1);
    expect(updated.single.lastShownAt, nine);
  });

  test('leaves terms whose turn has not come alone, so nothing is written '
      'that did not happen', () {
    final updated = recordShown(
      published: published(['a', 'b']),
      vocabs: [vocab('a'), vocab('b')],
      now: nine.add(const Duration(hours: 1)),
    );

    expect(updated.map((v) => v.id), isNot(contains('b')));
  });

  test('counts every appearance, not every term, when the queue cycles', () {
    // Three slots, one term: it came up three times while the app was closed.
    final updated = recordShown(
      published: published(['a', 'a', 'a']),
      vocabs: [vocab('a')],
      now: nine.add(const Duration(days: 1)),
    );

    expect(updated.single.timesShown, 3);
  });

  test('adds to the count a term already carried', () {
    final updated = recordShown(
      published: published(['a']),
      vocabs: [vocab('a', lastShownAt: DateTime.utc(2025), timesShown: 4)],
      now: nine.add(const Duration(days: 1)),
    );

    expect(updated.single.timesShown, 5);
  });

  test('dates a term by its most recent turn, not its first', () {
    final updated = recordShown(
      published: published(['a', 'a']),
      vocabs: [vocab('a')],
      now: nine.add(const Duration(days: 1)),
    );

    expect(updated.single.lastShownAt, nine.add(threeHours));
  });

  test('ignores an entry for a term that has since been deleted', () {
    final updated = recordShown(
      published: published(['gone']),
      vocabs: [vocab('a')],
      now: nine.add(const Duration(days: 1)),
    );

    expect(updated, isEmpty);
  });
}
