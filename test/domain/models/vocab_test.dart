import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';

void main() {
  // A fixed clock value keeps every assertion deterministic.
  final createdAt = DateTime.utc(2026, 1, 15, 9, 30);
  final shownAt = DateTime.utc(2026, 2, 1, 18, 0);

  Vocab buildVocab() => Vocab(
        id: 'v1',
        deckId: 'd1',
        term: 'la biblioteca',
        translation: 'die Bibliothek',
        sourceLanguage: 'es',
        targetLanguage: 'de',
        createdAt: createdAt,
      );

  group('Vocab construction', () {
    test('defaults timesShown to zero for a freshly created entry', () {
      expect(buildVocab().timesShown, 0);
    });

    test('leaves lastShownAt null until the entry has been displayed', () {
      expect(buildVocab().lastShownAt, isNull);
    });
  });

  group('Vocab equality', () {
    test('treats two entries with identical field values as equal', () {
      expect(buildVocab(), equals(buildVocab()));
    });

    test('treats entries with the same id but different terms as unequal', () {
      final renamed = buildVocab().copyWith(term: 'el libro');
      expect(renamed, isNot(equals(buildVocab())));
    });

    test('gives equal entries the same hashCode so they deduplicate in a Set', () {
      expect({buildVocab(), buildVocab()}, hasLength(1));
    });
  });

  group('Vocab.copyWith', () {
    test('replaces only the named field and preserves the rest', () {
      final updated = buildVocab().copyWith(timesShown: 3);

      expect(updated.timesShown, 3);
      expect(updated.term, 'la biblioteca');
      expect(updated.translation, 'die Bibliothek');
      expect(updated.createdAt, createdAt);
    });

    test('returns an equal entry when no replacements are given', () {
      expect(buildVocab().copyWith(), equals(buildVocab()));
    });

    test('sets lastShownAt, which starts out null', () {
      expect(buildVocab().copyWith(lastShownAt: shownAt).lastShownAt, shownAt);
    });
  });

  group('Vocab serialization', () {
    test('round-trips every field through toMap and fromMap', () {
      final original = buildVocab().copyWith(lastShownAt: shownAt, timesShown: 7);

      expect(Vocab.fromMap(original.toMap()), equals(original));
    });

    test('round-trips an entry whose lastShownAt is still null', () {
      final original = buildVocab();

      expect(Vocab.fromMap(original.toMap()).lastShownAt, isNull);
    });

    test('stores timestamps as UTC milliseconds so the map is database-ready', () {
      final map = buildVocab().toMap();

      expect(map['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(map['lastShownAt'], isNull);
    });
  });
}
