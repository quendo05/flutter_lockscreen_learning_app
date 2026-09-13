import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/config/defaults.dart';
import 'package:nagara/data/repositories/in_memory_deck_repository.dart';
import 'package:nagara/data/repositories/in_memory_settings_repository.dart';
import 'package:nagara/data/repositories/in_memory_vocab_repository.dart';
import 'package:nagara/data/repositories/vocab_repository.dart';
import 'package:nagara/data/services/schedule_store.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:nagara/domain/models/published_schedule.dart';
import 'package:nagara/domain/models/scheduled_vocab.dart';
import 'package:nagara/domain/models/vocab.dart';
import 'package:nagara/ui/home/view_models/home_view_model.dart';

import '../../support/schedule_store_doubles.dart';
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
    ScheduleStore? scheduleStore,
    DateTime? at,
  }) => HomeViewModel(
    scheduleStore: scheduleStore,
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
    clock: () => at ?? now,
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

  group('publishing to the lock screen', () {
    test('hands over the queue, so the lock screen can rotate while the app '
        'is closed', () async {
      final store = RecordingScheduleStore();
      final viewModel = buildViewModel(
        vocabRepository: InMemoryVocabRepository(
          initialEntries: [vocab('a'), vocab('b')],
        ),
        scheduleStore: store,
      );

      await viewModel.load();

      expect(store.published, hasLength(1));
      expect(store.last.entries.first.showAt, now);
      expect(store.last.deckName, 'Spanish basics');
      expect(store.last.interval, const Duration(hours: 3));
    });

    test(
      'publishes far enough ahead to outlast a spell away from the app',
      () async {
        final store = RecordingScheduleStore();
        final viewModel = buildViewModel(
          vocabRepository: InMemoryVocabRepository(
            initialEntries: [vocab('a')],
          ),
          scheduleStore: store,
        );

        await viewModel.load();

        expect(store.last.entries, hasLength(publishedScheduleLength));
      },
    );

    test('publishes an empty queue for an emptied deck, so the lock screen '
        'stops showing terms that are gone', () async {
      final store = RecordingScheduleStore();
      final viewModel = buildViewModel(scheduleStore: store);

      await viewModel.load();

      expect(store.published, hasLength(1));
      expect(store.last.entries, isEmpty);
    });

    test(
      'leaves the screen readable when the queue cannot be written',
      () async {
        final viewModel = buildViewModel(
          vocabRepository: InMemoryVocabRepository(
            initialEntries: [vocab('a')],
          ),
          scheduleStore: FailingScheduleStore(),
        );

        await viewModel.load();

        // The lock screen is stale, but the vocabulary was read fine and there
        // is nothing the user could do about it from here.
        expect(viewModel.loadError, isNull);
        expect(viewModel.nextUp, isNotNull);
      },
    );
  });

  group('catching up on what the lock screen showed', () {
    final deck = Deck(
      id: 'd1',
      name: 'Spanish basics',
      sourceLanguage: 'es',
      targetLanguage: 'de',
      displayInterval: const Duration(hours: 3),
      createdAt: now,
    );

    /// A queue published six hours ago, whose first two slots are behind us.
    PublishedSchedule alreadyRun(List<String> ids) => PublishedSchedule.of(
      generatedAt: now.subtract(const Duration(hours: 6)),
      deck: deck,
      upcoming: [
        for (var i = 0; i < ids.length; i++)
          ScheduledVocab(
            showAt: now.subtract(Duration(hours: 6 - i * 3)),
            vocab: vocab(ids[i]),
          ),
      ],
    );

    test('counts the turns taken while the app was closed', () async {
      final repository = InMemoryVocabRepository(
        initialEntries: [vocab('a'), vocab('b')],
      );
      final viewModel = buildViewModel(
        vocabRepository: repository,
        scheduleStore: RecordingScheduleStore(previous: alreadyRun(['a', 'b'])),
      );

      await viewModel.load();

      final stored = {
        for (final v in await repository.getByDeck('d1')) v.id: v,
      };

      expect(stored['a']!.timesShown, 1);
      expect(stored['a']!.lastShownAt, now.subtract(const Duration(hours: 6)));
      expect(stored['b']!.timesShown, 1);
    });

    test('lets what was just shown fall behind in the next queue', () async {
      final viewModel = buildViewModel(
        vocabRepository: InMemoryVocabRepository(
          initialEntries: [vocab('a'), vocab('b')],
        ),
        scheduleStore: RecordingScheduleStore(previous: alreadyRun(['a'])),
      );

      await viewModel.load();

      // 'a' had its turn, 'b' never has, so 'b' goes first now.
      expect(viewModel.nextUp!.vocab.id, 'b');
    });

    test(
      'counts a turn once, however often the app is opened afterwards',
      () async {
        final repository = InMemoryVocabRepository(
          initialEntries: [vocab('a'), vocab('b')],
        );
        final viewModel = buildViewModel(
          vocabRepository: repository,
          scheduleStore: RecordingScheduleStore(
            previous: alreadyRun(['a', 'b']),
          ),
        );

        await viewModel.load();
        // The queue published by the first load starts now, so none of its
        // entries have had their turn — this is what stops a second count.
        await viewModel.load();

        final stored = {
          for (final v in await repository.getByDeck('d1')) v.id: v,
        };

        expect(stored['a']!.timesShown, 1);
        expect(stored['b']!.timesShown, 1);
      },
    );

    test(
      'counts nothing on a first run, when no queue was ever published',
      () async {
        final repository = InMemoryVocabRepository(
          initialEntries: [vocab('a')],
        );
        final viewModel = buildViewModel(
          vocabRepository: repository,
          scheduleStore: RecordingScheduleStore(),
        );

        await viewModel.load();

        expect((await repository.getByDeck('d1')).single.timesShown, 0);
      },
    );

    test('leaves the screen readable when the counts cannot be written', () async {
      final viewModel = buildViewModel(
        vocabRepository: FailingOnSaveVocabRepository([vocab('a')]),
        scheduleStore: RecordingScheduleStore(previous: alreadyRun(['a'])),
      );

      await viewModel.load();

      // Nothing the user could act on from here, and the vocabulary read fine.
      expect(viewModel.loadError, isNull);
      expect(viewModel.nextUp, isNotNull);
    });
  });

  group('merely opening the app', () {
    test('leaves the term on the lock screen where it was', () async {
      final repository = InMemoryVocabRepository(
        initialEntries: [vocab('a'), vocab('b'), vocab('c')],
      );
      final store = RecordingScheduleStore();

      await buildViewModel(
        vocabRepository: repository,
        scheduleStore: store,
        at: now,
      ).load();
      final firstRun = store.last.entries.first;

      // Opened again an hour into a three hour slot, with nothing changed.
      await buildViewModel(
        vocabRepository: repository,
        scheduleStore: store,
        at: now.add(const Duration(hours: 1)),
      ).load();

      expect(store.last.entries.first, firstRun);
    });

    test('does not count the term still showing as done with', () async {
      final repository = InMemoryVocabRepository(
        initialEntries: [vocab('a'), vocab('b')],
      );
      final store = RecordingScheduleStore();

      await buildViewModel(
        vocabRepository: repository,
        scheduleStore: store,
        at: now,
      ).load();
      await buildViewModel(
        vocabRepository: repository,
        scheduleStore: store,
        at: now.add(const Duration(hours: 1)),
      ).load();

      expect(
        (await repository.getByDeck('d1')).every((v) => v.timesShown == 0),
        isTrue,
      );
    });

    test('keeps the later slots on their original boundaries', () async {
      final store = RecordingScheduleStore();
      final repository = InMemoryVocabRepository(
        initialEntries: [vocab('a'), vocab('b')],
      );

      await buildViewModel(
        vocabRepository: repository,
        scheduleStore: store,
        at: now,
      ).load();
      final firstRun = store.last.entries.take(3).toList();

      await buildViewModel(
        vocabRepository: repository,
        scheduleStore: store,
        at: now.add(const Duration(hours: 1)),
      ).load();

      expect(store.last.entries.take(3), firstRun);
    });
  });
}
