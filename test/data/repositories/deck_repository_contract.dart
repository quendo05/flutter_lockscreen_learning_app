import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/data/repositories/deck_repository.dart';
import 'package:nagara/domain/models/deck.dart';

Deck contractDeck(String id, {String? name, DateTime? createdAt}) => Deck(
  id: id,
  name: name ?? 'deck-$id',
  sourceLanguage: 'es',
  targetLanguage: 'de',
  displayInterval: const Duration(hours: 3),
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
);

/// The behaviour every [DeckRepository] implementation must satisfy.
void runDeckRepositoryContract(Future<DeckRepository> Function() create) {
  late DeckRepository repository;

  setUp(() async => repository = await create());

  group('getAll', () {
    test('lists decks oldest first, so the list order stays stable', () async {
      await repository.save(
        contractDeck('third', createdAt: DateTime.utc(2026, 3, 1)),
      );
      await repository.save(
        contractDeck('first', createdAt: DateTime.utc(2026, 1, 1)),
      );
      await repository.save(
        contractDeck('second', createdAt: DateTime.utc(2026, 2, 1)),
      );

      final ids = (await repository.getAll()).map((d) => d.id).toList();

      expect(ids, ['first', 'second', 'third']);
    });

    test(
      'returns a copy, so mutating the result cannot corrupt the store',
      () async {
        await repository.save(contractDeck('a'));

        (await repository.getAll()).clear();

        expect(await repository.getAll(), hasLength(1));
      },
    );

    test('preserves every field through a save and read cycle', () async {
      final deck = contractDeck('a', name: 'Spanish basics');
      await repository.save(deck);

      expect((await repository.getAll()).single, equals(deck));
    });
  });

  group('save', () {
    test('adds a deck that was not stored before', () async {
      await repository.save(contractDeck('a'));

      expect(await repository.getById('a'), equals(contractDeck('a')));
    });

    test('replaces the existing deck when the id is already stored', () async {
      await repository.save(contractDeck('a'));
      await repository.save(contractDeck('a', name: 'Renamed'));

      final stored = await repository.getAll();

      expect(stored, hasLength(1));
      expect(stored.single.name, 'Renamed');
    });
  });

  group('getById', () {
    test('returns null when no deck carries that id', () async {
      expect(await repository.getById('missing'), isNull);
    });
  });

  group('delete', () {
    test('removes the deck with the given id', () async {
      await repository.save(contractDeck('a'));

      await repository.delete('a');

      expect(await repository.getById('a'), isNull);
    });

    test('leaves the other decks alone', () async {
      await repository.save(contractDeck('a'));
      await repository.save(contractDeck('b'));

      await repository.delete('a');

      expect((await repository.getAll()).single.id, 'b');
    });

    test('is a no-op for an unknown id rather than throwing', () async {
      await expectLater(repository.delete('missing'), completes);
    });
  });
}
