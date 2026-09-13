import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/config/defaults.dart';
import 'package:nagara/data/repositories/in_memory_deck_repository.dart';
import 'package:nagara/data/repositories/in_memory_settings_repository.dart';
import 'package:nagara/data/repositories/in_memory_vocab_repository.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:nagara/domain/models/vocab.dart';
import 'package:nagara/ui/deck_list/view_models/deck_list_view_model.dart';

void main() {
  final now = DateTime.utc(2026, 8, 1, 10);

  Deck deck(String id, {String? name}) => Deck(
    id: id,
    name: name ?? 'deck-$id',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: const Duration(hours: 3),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Vocab vocab(String id, String deckId) => Vocab(
    id: id,
    deckId: deckId,
    term: 'term-$id',
    translation: 'translation-$id',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  DeckListViewModel buildViewModel({
    List<Deck> decks = const [],
    List<Vocab> vocabs = const [],
    String activeDeckId = defaultDeckId,
  }) {
    var counter = 0;
    return DeckListViewModel(
      deckRepository: InMemoryDeckRepository(initialDecks: decks),
      vocabRepository: InMemoryVocabRepository(initialEntries: vocabs),
      settingsRepository: InMemorySettingsRepository(
        initialActiveDeckId: activeDeckId,
      ),
      clock: () => now,
      idGenerator: () => 'new-${++counter}',
    );
  }

  group('load', () {
    test('lists the stored decks', () async {
      final viewModel = buildViewModel(decks: [deck('a'), deck('b')]);

      await viewModel.load();

      expect(viewModel.decks.map((d) => d.id), ['a', 'b']);
      expect(viewModel.isLoading, isFalse);
    });

    test('reports which deck is feeding the lock screen', () async {
      final viewModel = buildViewModel(
        decks: [deck('a'), deck('b')],
        activeDeckId: 'b',
      );

      await viewModel.load();

      expect(viewModel.activeDeckId, 'b');
    });

    test('counts the terms in each deck', () async {
      final viewModel = buildViewModel(
        decks: [deck('a'), deck('b')],
        vocabs: [vocab('1', 'a'), vocab('2', 'a'), vocab('3', 'b')],
      );

      await viewModel.load();

      expect(viewModel.termCountFor('a'), 2);
      expect(viewModel.termCountFor('b'), 1);
    });

    test('counts an untouched deck as empty', () async {
      final viewModel = buildViewModel(decks: [deck('a')]);

      await viewModel.load();

      expect(viewModel.termCountFor('a'), 0);
    });
  });

  group('createDeck', () {
    test('stores the new deck and shows it in the list', () async {
      final viewModel = buildViewModel();

      await viewModel.createDeck(
        'Spanish basics',
        sourceLanguage: 'es',
        targetLanguage: 'de',
      );

      expect(viewModel.decks.single.name, 'Spanish basics');
      expect(viewModel.decks.single.id, 'new-1');
    });

    test('stores the pair the deck is to be studied in', () async {
      final viewModel = buildViewModel();

      await viewModel.createDeck(
        'Travel French',
        sourceLanguage: 'fr',
        targetLanguage: 'en',
      );

      expect(viewModel.decks.single.sourceLanguage, 'fr');
      expect(viewModel.decks.single.targetLanguage, 'en');
    });

    test('starts a new deck at the pace the app defaults to', () async {
      final viewModel = buildViewModel();

      await viewModel.createDeck(
        'Travel',
        sourceLanguage: 'fr',
        targetLanguage: 'en',
      );

      expect(viewModel.decks.single.displayInterval, defaultDisplayInterval);
    });

    test('trims surrounding whitespace from the name', () async {
      final viewModel = buildViewModel();

      await viewModel.createDeck(
        '  Travel  ',
        sourceLanguage: 'es',
        targetLanguage: 'de',
      );

      expect(viewModel.decks.single.name, 'Travel');
    });

    test('refuses a blank name instead of storing an unnamed deck', () async {
      final viewModel = buildViewModel();

      await viewModel.createDeck(
        '   ',
        sourceLanguage: 'es',
        targetLanguage: 'de',
      );

      expect(viewModel.decks, isEmpty);
      expect(viewModel.validationMessage, isNotNull);
    });

    test('leaves the existing decks alone when the name is rejected', () async {
      final viewModel = buildViewModel(decks: [deck('a', name: 'Kept')]);
      await viewModel.load();

      await viewModel.createDeck(
        '',
        sourceLanguage: 'es',
        targetLanguage: 'de',
      );

      expect(viewModel.decks.single.name, 'Kept');
      expect(viewModel.loadError, isNull);
    });

    test('does not change which deck is active', () async {
      final viewModel = buildViewModel(activeDeckId: defaultDeckId);
      await viewModel.load();

      await viewModel.createDeck(
        'Travel',
        sourceLanguage: 'es',
        targetLanguage: 'de',
      );

      expect(viewModel.activeDeckId, defaultDeckId);
    });
  });

  group('setActiveDeck', () {
    test('moves the lock screen to the chosen deck', () async {
      final viewModel = buildViewModel(decks: [deck('a'), deck('b')]);
      await viewModel.load();

      await viewModel.setActiveDeck('b');

      expect(viewModel.activeDeckId, 'b');
    });

    test('survives a reload, because it is stored as a preference', () async {
      final viewModel = buildViewModel(decks: [deck('a'), deck('b')]);
      await viewModel.load();
      await viewModel.setActiveDeck('b');

      await viewModel.load();

      expect(viewModel.activeDeckId, 'b');
    });
  });

  test('notifies listeners so the screen rebuilds', () async {
    final viewModel = buildViewModel();
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    await viewModel.load();

    expect(notifications, greaterThan(0));
  });
}
