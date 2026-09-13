import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/data/repositories/in_memory_deck_repository.dart';
import 'package:nagara/data/repositories/in_memory_vocab_repository.dart';
import 'package:nagara/data/services/demo_decks.dart';

void main() {
  late InMemoryDeckRepository decks;
  late InMemoryVocabRepository vocabs;

  setUp(() {
    decks = InMemoryDeckRepository();
    vocabs = InMemoryVocabRepository();
  });

  Future<void> seed() => seedDemoDecks(
    deckRepository: decks,
    vocabRepository: vocabs,
    clock: () => DateTime.utc(2026, 1, 1),
  );

  test('adds one deck per language', () async {
    await seed();

    expect((await decks.getAll()).map((d) => d.sourceLanguage), [
      'ja',
      'en',
      'es',
    ]);
  });

  test('gives every deck the same ten words, so the three can be compared '
      'side by side', () async {
    await seed();

    for (final deck in await decks.getAll()) {
      expect(await vocabs.getByDeck(deck.id), hasLength(10));
    }
  });

  test('translates all of them into the language the decks are studied '
      'from', () async {
    await seed();

    for (final deck in await decks.getAll()) {
      expect(deck.targetLanguage, 'de');
      for (final vocab in await vocabs.getByDeck(deck.id)) {
        expect(vocab.targetLanguage, 'de');
        expect(vocab.sourceLanguage, deck.sourceLanguage);
      }
    }
  });

  test('lines the words up, so the same idea sits at the same position in '
      'each deck', () async {
    await seed();

    final all = await decks.getAll();
    final translations = <List<String>>[];
    for (final deck in all) {
      final entries = await vocabs.getByDeck(deck.id);
      translations.add(
        (entries.toList()..sort((a, b) => a.id.compareTo(b.id)))
            .map((v) => v.translation)
            .toList(),
      );
    }

    expect(translations[0], translations[1]);
    expect(translations[1], translations[2]);
  });

  test('paces the three decks differently, so a lock screen can be watched '
      'without waiting hours', () async {
    await seed();

    final intervals = (await decks.getAll()).map((d) => d.displayInterval);

    expect(intervals.toSet(), hasLength(3));
  });

  test('leaves nothing duplicated when seeded twice', () async {
    await seed();
    await seed();

    expect(await decks.getAll(), hasLength(3));
    for (final deck in await decks.getAll()) {
      expect(await vocabs.getByDeck(deck.id), hasLength(10));
    }
  });

  test('leaves decks the user made alone', () async {
    await seedDemoDecks(
      deckRepository: decks,
      vocabRepository: vocabs,
      clock: () => DateTime.utc(2026, 1, 1),
    );
    final before = (await decks.getAll()).length;

    expect(before, 3);
  });
}
