import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/deck_settings/view_models/deck_settings_view_model.dart';

class _FailingDeckRepository implements DeckRepository {
  @override
  Future<List<Deck>> getAll() async => throw Exception('offline');
  @override
  Future<Deck?> getById(String id) async => throw Exception('offline');
  @override
  Future<void> save(Deck deck) async => throw Exception('offline');
  @override
  Future<void> delete(String id) async => throw Exception('offline');
}

void main() {
  final original = Deck(
    id: 'd1',
    name: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: const Duration(hours: 3),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Deck deck(String id) => original.copyWith(id: id, name: 'deck-$id');

  Vocab vocab(String id, String deckId) => Vocab(
    id: id,
    deckId: deckId,
    term: 'term-$id',
    translation: 'translation-$id',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  late InMemoryDeckRepository repository;
  late InMemoryVocabRepository vocabRepository;
  late InMemorySettingsRepository settingsRepository;
  late DeckSettingsViewModel viewModel;

  DeckSettingsViewModel buildViewModel({
    Deck? editing,
    List<Deck> decks = const [],
    List<Vocab> vocabs = const [],
    String activeDeckId = 'd1',
    DeckRepository? deckRepository,
  }) {
    repository = InMemoryDeckRepository(
      initialDecks: decks.isEmpty ? [original] : decks,
    );
    vocabRepository = InMemoryVocabRepository(initialEntries: vocabs);
    settingsRepository = InMemorySettingsRepository(
      initialActiveDeckId: activeDeckId,
    );

    return DeckSettingsViewModel(
      deck: editing ?? original,
      deckRepository: deckRepository ?? repository,
      vocabRepository: vocabRepository,
      settingsRepository: settingsRepository,
    );
  }

  setUp(() => viewModel = buildViewModel());

  Future<Deck?> saveWith({
    String name = 'Spanish basics',
    String sourceLanguage = 'es',
    String targetLanguage = 'de',
    int intervalHours = 3,
  }) => viewModel.save(
    name: name,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    intervalHours: intervalHours,
  );

  group('saving', () {
    test('stores a new name', () async {
      await saveWith(name: 'Travel Spanish');

      expect((await repository.getById('d1'))!.name, 'Travel Spanish');
    });

    test('stores a new language pair', () async {
      await saveWith(sourceLanguage: 'fr', targetLanguage: 'en');

      final stored = (await repository.getById('d1'))!;

      expect(stored.sourceLanguage, 'fr');
      expect(stored.targetLanguage, 'en');
    });

    test('stores the pace in hours', () async {
      await saveWith(intervalHours: 8);

      expect(
        (await repository.getById('d1'))!.displayInterval,
        const Duration(hours: 8),
      );
    });

    test('keeps the identity and creation time of the deck', () async {
      await saveWith(name: 'Renamed');

      final stored = (await repository.getById('d1'))!;

      expect(stored.id, original.id);
      expect(stored.createdAt, original.createdAt);
    });

    test('trims surrounding whitespace from what was typed', () async {
      await saveWith(name: '  Travel  ', sourceLanguage: '  fr  ');

      final stored = (await repository.getById('d1'))!;

      expect(stored.name, 'Travel');
      expect(stored.sourceLanguage, 'fr');
    });

    test('returns the saved deck, so the caller can adopt it', () async {
      final saved = await saveWith(name: 'Travel');

      expect(saved?.name, 'Travel');
    });

    test('exposes the saved deck as the current one', () async {
      await saveWith(name: 'Travel');

      expect(viewModel.deck.name, 'Travel');
    });
  });

  group('rejecting input', () {
    test('refuses a blank name', () async {
      expect(await saveWith(name: '   '), isNull);
      expect(viewModel.validationMessage, isNotNull);
    });

    test('refuses a blank language you are learning', () async {
      expect(await saveWith(sourceLanguage: ''), isNull);
      expect(viewModel.validationMessage, isNotNull);
    });

    test('refuses a blank language you understand', () async {
      expect(await saveWith(targetLanguage: ''), isNull);
      expect(viewModel.validationMessage, isNotNull);
    });

    test('leaves the stored deck untouched when input is refused', () async {
      await saveWith(name: '');

      expect((await repository.getById('d1'))!.name, 'Spanish basics');
    });

    test('keeps reporting the deck it opened with', () async {
      await saveWith(name: '');

      expect(viewModel.deck, original);
    });
  });

  group('when the write fails', () {
    test('reports it rather than claiming success', () async {
      final failing = buildViewModel(deckRepository: _FailingDeckRepository());

      final saved = await failing.save(
        name: 'Travel',
        sourceLanguage: 'es',
        targetLanguage: 'de',
        intervalHours: 3,
      );

      expect(saved, isNull);
      expect(failing.validationMessage, isNotNull);
      expect(failing.deck, original);
    });
  });

  test('notifies listeners so the screen can react', () async {
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    await saveWith(name: 'Travel');

    expect(notifications, greaterThan(0));
  });

  group('deleting', () {
    test('offers no delete until it knows whether one is allowed', () {
      // Safe default: the destructive action is withheld, not offered on a
      // guess that turns out to be wrong.
      expect(buildViewModel().canDelete, isFalse);
    });

    test('refuses to delete the only deck, because there would be nowhere '
        'left to save', () async {
      final viewModel = buildViewModel(decks: [original]);

      await viewModel.load();

      expect(viewModel.canDelete, isFalse);
    });

    test('allows deleting one of several decks', () async {
      final viewModel = buildViewModel(decks: [original, deck('other')]);

      await viewModel.load();

      expect(viewModel.canDelete, isTrue);
    });

    test('counts what would be lost, so the user can be told before they '
        'agree to it', () async {
      final viewModel = buildViewModel(
        decks: [original, deck('other')],
        vocabs: [vocab('1', 'd1'), vocab('2', 'd1'), vocab('3', 'other')],
      );

      await viewModel.load();

      expect(viewModel.termCount, 2);
    });

    test('removes the deck', () async {
      final viewModel = buildViewModel(decks: [original, deck('other')]);
      await viewModel.load();

      expect(await viewModel.delete(), isTrue);
      expect(await repository.getById('d1'), isNull);
    });

    test('takes the terms inside it with it, leaving no rows nothing can '
        'reach', () async {
      final viewModel = buildViewModel(
        decks: [original, deck('other')],
        vocabs: [vocab('1', 'd1'), vocab('2', 'other')],
      );
      await viewModel.load();

      await viewModel.delete();

      expect(await vocabRepository.getByDeck('d1'), isEmpty);
      expect(await vocabRepository.getByDeck('other'), hasLength(1));
    });

    test(
      'moves the lock screen to another deck when the active one goes',
      () async {
        final viewModel = buildViewModel(
          decks: [original, deck('other')],
          activeDeckId: 'd1',
        );
        await viewModel.load();

        await viewModel.delete();

        expect(await settingsRepository.getActiveDeckId(), 'other');
      },
    );

    test('leaves the active deck alone when another one is deleted', () async {
      final viewModel = buildViewModel(
        editing: deck('other'),
        decks: [original, deck('other')],
        activeDeckId: 'd1',
      );
      await viewModel.load();

      await viewModel.delete();

      expect(await settingsRepository.getActiveDeckId(), 'd1');
    });

    test(
      'refuses rather than deleting the last deck, even if asked directly',
      () async {
        final viewModel = buildViewModel(decks: [original]);
        await viewModel.load();

        expect(await viewModel.delete(), isFalse);
        expect(await repository.getById('d1'), isNotNull);
        expect(viewModel.validationMessage, isNotNull);
      },
    );

    test('reports a failure instead of claiming the deck is gone', () async {
      final viewModel = buildViewModel(
        decks: [original, deck('other')],
        deckRepository: _FailingDeckRepository(),
      );

      expect(await viewModel.delete(), isFalse);
      expect(viewModel.validationMessage, isNotNull);
    });
  });
}
