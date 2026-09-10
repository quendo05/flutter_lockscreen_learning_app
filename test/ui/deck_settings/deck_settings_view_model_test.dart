import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/ui/deck_settings/view_models/deck_settings_view_model.dart';

class _FailingDeckRepository implements DeckRepository {
  @override
  Future<List<Deck>> getAll() async => throw Exception('offline');
  @override
  Future<Deck?> getById(String id) async => throw Exception('offline');
  @override
  Future<void> save(Deck deck) async => throw Exception('offline');
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

  late InMemoryDeckRepository repository;
  late DeckSettingsViewModel viewModel;

  setUp(() {
    repository = InMemoryDeckRepository(initialDecks: [original]);
    viewModel = DeckSettingsViewModel(deck: original, repository: repository);
  });

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
      final failing = DeckSettingsViewModel(
        deck: original,
        repository: _FailingDeckRepository(),
      );

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
}
