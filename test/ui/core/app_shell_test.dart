import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/ui/core/widgets/app_shell.dart';

void main() {
  Deck seededDeck() => Deck.initial(createdAt: DateTime.utc(2026, 1, 1));

  Future<void> pumpShell(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          vocabRepository: InMemoryVocabRepository(),
          deckRepository: InMemoryDeckRepository(initialDecks: [seededDeck()]),
          settingsRepository: InMemorySettingsRepository(),
        ),
      ),
    );
  }

  testWidgets('opens on the home screen', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.text('LockScreenVocab'), findsOneWidget);
  });

  testWidgets('offers both destinations in the navigation bar', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Decks'), findsOneWidget);
  });

  testWidgets('shows the deck list when its destination is chosen',
      (tester) async {
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

    expect(find.text('LockScreenVocab'), findsOneWidget);
  });

  testWidgets('sends the empty-state action through to the deck list',
      (tester) async {
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

  testWidgets('reflects a term added inside a deck on the home screen',
      (tester) async {
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
}
