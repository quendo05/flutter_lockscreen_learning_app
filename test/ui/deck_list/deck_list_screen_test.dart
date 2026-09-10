import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/deck_list/view_models/deck_list_view_model.dart';
import 'package:lockscreen_learning_app/ui/deck_list/widgets/deck_list_screen.dart';

class _FailingDeckRepository implements DeckRepository {
  @override
  Future<List<Deck>> getAll() async => throw Exception('offline');
  @override
  Future<Deck?> getById(String id) async => throw Exception('offline');
  @override
  Future<void> save(Deck deck) async => throw Exception('offline');
}

void main() {
  final opened = <String>[];

  setUp(opened.clear);

  Deck deck(String id, String name) =>
      Deck(id: id, name: name, createdAt: DateTime.utc(2026, 1, 1));

  Vocab vocab(String id, String deckId) => Vocab(
        id: id,
        deckId: deckId,
        term: 'term-$id',
        translation: 'translation-$id',
        sourceLanguage: 'es',
        targetLanguage: 'de',
        createdAt: DateTime.utc(2026, 1, 1),
      );

  Future<void> pumpScreen(
    WidgetTester tester, {
    DeckRepository? deckRepository,
    List<Vocab> vocabs = const [],
    String activeDeckId = 'a',
  }) {
    var counter = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: DeckListScreen(
          viewModel: DeckListViewModel(
            deckRepository: deckRepository ?? InMemoryDeckRepository(),
            vocabRepository: InMemoryVocabRepository(initialEntries: vocabs),
            settingsRepository: InMemorySettingsRepository(
              initialActiveDeckId: activeDeckId,
            ),
            idGenerator: () => 'new-${++counter}',
          ),
          onOpenDeck: (deck) => opened.add(deck.id),
        ),
      ),
    );
  }

  testWidgets('names the screen', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Decks'), findsOneWidget);
  });

  group('with no decks', () {
    testWidgets('invites the user to create one', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('No decks yet'), findsOneWidget);
    });
  });

  group('with decks', () {
    testWidgets('lists each deck with how many terms it holds',
        (tester) async {
      await pumpScreen(
        tester,
        deckRepository: InMemoryDeckRepository(
          initialDecks: [deck('a', 'Spanish basics')],
        ),
        vocabs: [vocab('1', 'a'), vocab('2', 'a')],
      );
      await tester.pumpAndSettle();

      expect(find.text('Spanish basics'), findsOneWidget);
      expect(find.textContaining('2 terms'), findsOneWidget);
    });

    testWidgets('uses the singular for a deck holding one term',
        (tester) async {
      await pumpScreen(
        tester,
        deckRepository: InMemoryDeckRepository(
          initialDecks: [deck('a', 'Spanish basics')],
        ),
        vocabs: [vocab('1', 'a')],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1 term'), findsOneWidget);
    });

    testWidgets('says in words which deck is on the lock screen',
        (tester) async {
      await pumpScreen(
        tester,
        deckRepository: InMemoryDeckRepository(
          initialDecks: [deck('a', 'Active one'), deck('b', 'Other')],
        ),
        activeDeckId: 'a',
      );
      await tester.pumpAndSettle();

      // Stated as text, not only as an icon, so the state is not colour-only.
      expect(find.textContaining('on your lock screen'), findsOneWidget);
    });

    testWidgets('opens a deck when its row is tapped', (tester) async {
      await pumpScreen(
        tester,
        deckRepository: InMemoryDeckRepository(
          initialDecks: [deck('a', 'Spanish basics')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spanish basics'));
      await tester.pumpAndSettle();

      expect(opened, ['a']);
    });

    testWidgets('moves the lock screen to another deck', (tester) async {
      await pumpScreen(
        tester,
        deckRepository: InMemoryDeckRepository(
          initialDecks: [deck('a', 'Active one'), deck('b', 'Other')],
        ),
        activeDeckId: 'a',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Use Other for your lock screen'));
      await tester.pumpAndSettle();

      expect(
        find.byTooltip('Other is on your lock screen'),
        findsOneWidget,
      );
    });
  });

  testWidgets('creates a deck through the form', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create deck'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('deck-name-field')), 'Travel');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('No decks yet'), findsNothing);
  });

  testWidgets('keeps Create unavailable until the name has content',
      (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create deck'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('offers a retry when the store cannot be read', (tester) async {
    await pumpScreen(tester, deckRepository: _FailingDeckRepository());
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No decks yet'), findsNothing);
  });
}
