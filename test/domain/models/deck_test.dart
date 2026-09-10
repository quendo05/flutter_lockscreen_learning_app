import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';

void main() {
  final createdAt = DateTime.utc(2026, 3, 2, 14);

  Deck buildDeck() =>
      Deck(id: 'd1', name: 'Spanish basics', createdAt: createdAt);

  group('Deck equality', () {
    test('treats two decks with identical field values as equal', () {
      expect(buildDeck(), equals(buildDeck()));
    });

    test('treats a renamed deck as a different value', () {
      final renamed = Deck(id: 'd1', name: 'Travel', createdAt: createdAt);

      expect(renamed, isNot(equals(buildDeck())));
    });

    test(
      'gives equal decks the same hashCode so they deduplicate in a Set',
      () {
        expect({buildDeck(), buildDeck()}, hasLength(1));
      },
    );
  });

  group('Deck.initial', () {
    test('carries the id and name the schema seeds', () {
      final deck = Deck.initial(createdAt: createdAt);

      expect(deck.id, defaultDeckId);
      expect(deck.name, defaultDeckName);
      expect(deck.createdAt, createdAt);
    });
  });

  group('Deck serialization', () {
    test('round-trips every field through toMap and fromMap', () {
      final original = buildDeck();

      expect(Deck.fromMap(original.toMap()), equals(original));
    });

    test(
      'stores createdAt as UTC milliseconds so the map is database-ready',
      () {
        expect(
          buildDeck().toMap()['createdAt'],
          createdAt.millisecondsSinceEpoch,
        );
      },
    );
  });
}
