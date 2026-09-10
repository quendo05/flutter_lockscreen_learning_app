import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/home/view_models/home_view_model.dart';

import '../../support/vocab_repository_doubles.dart';

void main() {
  final now = DateTime.utc(2026, 7, 1, 9);

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

  HomeViewModel buildViewModel({
    VocabRepository? vocabRepository,
    Duration interval = const Duration(hours: 3),
  }) => HomeViewModel(
    vocabRepository: vocabRepository ?? InMemoryVocabRepository(),
    deckRepository: InMemoryDeckRepository(
      initialDecks: [
        Deck(
          id: 'd1',
          name: 'Spanish basics',
          sourceLanguage: 'es',
          targetLanguage: 'de',
          displayInterval: interval,
          createdAt: now,
        ),
      ],
    ),
    settingsRepository: InMemorySettingsRepository(initialActiveDeckId: 'd1'),
    clock: () => now,
  );

  group('with no vocabulary saved', () {
    test('reports an empty collection rather than an error', () async {
      final viewModel = buildViewModel();

      await viewModel.load();

      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.loadError, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('has no term to announce', () async {
      final viewModel = buildViewModel();

      await viewModel.load();

      expect(viewModel.nextUp, isNull);
    });

    test('counts zero saved terms', () async {
      final viewModel = buildViewModel();

      await viewModel.load();

      expect(viewModel.vocabularyCount, 0);
    });
  });

  group('with vocabulary saved', () {
    Future<HomeViewModel> loadedWith(List<Vocab> entries) async {
      final viewModel = buildViewModel(
        vocabRepository: InMemoryVocabRepository(initialEntries: entries),
      );
      await viewModel.load();
      return viewModel;
    }

    test('counts every saved term', () async {
      final viewModel = await loadedWith([vocab('a'), vocab('b'), vocab('c')]);

      expect(viewModel.vocabularyCount, 3);
    });

    test('announces the term most in need of practice', () async {
      final viewModel = await loadedWith([
        vocab(
          'practised',
          lastShownAt: DateTime.utc(2026, 6, 30),
          timesShown: 5,
        ),
        vocab('untouched'),
      ]);

      expect(viewModel.nextUp?.vocab.id, 'untouched');
    });

    test('schedules that term for the current moment', () async {
      final viewModel = await loadedWith([vocab('a')]);

      expect(viewModel.nextUp?.showAt, now);
    });

    test('reports when the term after it is due', () async {
      final viewModel = await loadedWith([vocab('a'), vocab('b')]);

      expect(viewModel.followingAt, now.add(const Duration(hours: 3)));
    });

    test('reflects the configured interval', () async {
      final viewModel = buildViewModel(
        vocabRepository: InMemoryVocabRepository(initialEntries: [vocab('a')]),
        interval: const Duration(hours: 8),
      );
      await viewModel.load();

      expect(viewModel.displayInterval, const Duration(hours: 8));
      expect(viewModel.followingAt, now.add(const Duration(hours: 8)));
    });

    test('is not treated as an empty collection', () async {
      final viewModel = await loadedWith([vocab('a')]);

      expect(viewModel.isEmpty, isFalse);
    });
  });

  group('when the store cannot be read', () {
    test('surfaces a message instead of a term', () async {
      final viewModel = buildViewModel(
        vocabRepository: FailingVocabRepository(),
      );

      await viewModel.load();

      expect(viewModel.loadError, isNotNull);
      expect(viewModel.nextUp, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('does not claim the collection is empty', () async {
      final viewModel = buildViewModel(
        vocabRepository: FailingVocabRepository(),
      );

      await viewModel.load();

      expect(viewModel.isEmpty, isFalse);
    });
  });

  group('the active deck', () {
    test(
      'is named, so the summary can say which collection it describes',
      () async {
        final viewModel = buildViewModel();

        await viewModel.load();

        expect(viewModel.activeDeckName, 'Spanish basics');
      },
    );

    test('is the only deck whose terms reach the lock screen', () async {
      final viewModel = buildViewModel(
        vocabRepository: InMemoryVocabRepository(
          initialEntries: [
            vocab('mine'),
            vocab('theirs').copyWith(deckId: 'another-deck'),
          ],
        ),
      );

      await viewModel.load();

      expect(viewModel.vocabularyCount, 1);
      expect(viewModel.nextUp?.vocab.id, 'mine');
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
