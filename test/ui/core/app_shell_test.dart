import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/ui/core/widgets/app_shell.dart';

import '../../support/schedule_store_doubles.dart';

void main() {
  Deck seededDeck() => Deck.initial(createdAt: DateTime.utc(2026, 1, 1));

  late InMemoryDeckRepository deckRepository;

  Future<void> pumpShell(
    WidgetTester tester, {
    RecordingScheduleStore? store,
    List<Deck>? decks,
  }) {
    deckRepository = InMemoryDeckRepository(
      initialDecks: decks ?? [seededDeck()],
    );
    return tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          vocabRepository: InMemoryVocabRepository(),
          deckRepository: deckRepository,
          settingsRepository: InMemorySettingsRepository(),
          scheduleStore: store,
        ),
      ),
    );
  }

  /// Works through the confirmation the settings screen puts in the way.
  Future<void> deleteOpenDeck(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.text('Delete deck'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
  }

  /// Drives the app all the way to the background and back, the way the
  /// platform does it.
  Future<void> sendToBackground(WidgetTester tester) async {
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  Future<void> bringToForeground(WidgetTester tester) async {
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the home screen', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.text('Nagara'), findsOneWidget);
  });

  testWidgets('offers both destinations in the navigation bar', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Decks'), findsOneWidget);
  });

  testWidgets('shows the deck list when its destination is chosen', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.text(defaultDeckName), findsOneWidget);
    expect(find.byTooltip('Create deck'), findsOneWidget);
  });

  testWidgets('returns to the home screen from the deck list', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Nagara'), findsOneWidget);
  });

  testWidgets('sends the empty-state action through to the deck list', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your first term'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Create deck'), findsOneWidget);
  });

  testWidgets('opens a deck onto its own vocabulary', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(defaultDeckName));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add vocabulary'), findsOneWidget);
    expect(find.text('No vocabulary yet'), findsOneWidget);
  });

  testWidgets('reflects a term added inside a deck on the home screen', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(defaultDeckName));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add vocabulary'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
    await tester.enterText(
      find.byKey(const Key('translation-field')),
      'das Buch',
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Back out of the deck, then over to home.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('el libro'), findsOneWidget);
    expect(find.text('1 term saved'), findsOneWidget);
  });

  testWidgets('renames a deck from the deck list, without opening it', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings for $defaultDeckName'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deck-name-field')),
      'Spanish basics',
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Back on the list, which has reloaded to show the new name.
    expect(find.text('Spanish basics'), findsOneWidget);
    expect(find.text(defaultDeckName), findsNothing);
  });

  group('keeping the lock screen in step with the app', () {
    testWidgets('publishes again on the way to the background, which is the '
        'moment the queue starts being needed', (tester) async {
      final store = RecordingScheduleStore();
      await pumpShell(tester, store: store);
      await tester.pumpAndSettle();
      final onOpen = store.published.length;

      await sendToBackground(tester);

      expect(store.published.length, greaterThan(onOpen));
    });

    testWidgets('publishes again on coming back, so turns taken while away '
        'are accounted for', (tester) async {
      final store = RecordingScheduleStore();
      await pumpShell(tester, store: store);
      await tester.pumpAndSettle();
      await sendToBackground(tester);
      final onLeaving = store.published.length;

      await bringToForeground(tester);

      expect(store.published.length, greaterThan(onLeaving));
    });

    testWidgets('still works when nothing native reads the queue', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      await sendToBackground(tester);

      // The web build passes no store at all; going to the background must
      // not be the thing that breaks it.
      expect(tester.takeException(), isNull);
    });
  });

  group('deleting a deck', () {
    final travel = Deck(
      id: 'travel',
      name: 'Travel',
      sourceLanguage: 'es',
      targetLanguage: 'de',
      displayInterval: const Duration(hours: 3),
      createdAt: DateTime.utc(2026, 2, 1),
    );

    testWidgets('takes it off the deck list', (tester) async {
      await pumpShell(tester, decks: [seededDeck(), travel]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decks'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings for Travel'));
      await tester.pumpAndSettle();
      await deleteOpenDeck(tester);

      expect(find.text('Travel'), findsNothing);
      expect(find.text(defaultDeckName), findsOneWidget);
      expect(await deckRepository.getById('travel'), isNull);
    });

    testWidgets('closes the deck being looked at, which has nothing left to '
        'show', (tester) async {
      await pumpShell(tester, decks: [seededDeck(), travel]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decks'));
      await tester.pumpAndSettle();

      // Into the deck, then into its settings from there.
      await tester.tap(find.text('Travel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Deck settings'));
      await tester.pumpAndSettle();

      await deleteOpenDeck(tester);

      // Back on the deck list, not stranded on a page for a deck that is gone.
      expect(find.byTooltip('Create deck'), findsOneWidget);
      expect(find.text('Travel'), findsNothing);
    });
  });
}
