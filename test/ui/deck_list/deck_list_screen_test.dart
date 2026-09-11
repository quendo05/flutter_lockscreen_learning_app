import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/config/defaults.dart';
import 'package:lockscreen_learning_app/config/languages.dart';
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
  @override
  Future<void> delete(String id) async => throw Exception('offline');
}

void main() {
  final opened = <String>[];
  late DeckRepository createdInto;
  final settingsOpened = <String>[];

  setUp(() {
    opened.clear();
    settingsOpened.clear();
  });

  Deck deck(String id, String name) => Deck(
    id: id,
    name: name,
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

  /// Searches one of the sheet's language pickers and chooses the match.
  Future<void> pickLanguage(
    WidgetTester tester,
    String fieldKey,
    String name,
  ) async {
    final field = find.descendant(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(TextField),
    );

    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, name);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, name));
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    DeckRepository? deckRepository,
    List<Vocab> vocabs = const [],
    String activeDeckId = 'a',
  }) {
    var counter = 0;
    createdInto = deckRepository ?? InMemoryDeckRepository();
    return tester.pumpWidget(
      MaterialApp(
        home: DeckListScreen(
          viewModel: DeckListViewModel(
            deckRepository: createdInto,
            vocabRepository: InMemoryVocabRepository(initialEntries: vocabs),
            settingsRepository: InMemorySettingsRepository(
              initialActiveDeckId: activeDeckId,
            ),
            idGenerator: () => 'new-${++counter}',
          ),
          onOpenDeck: (deck) => opened.add(deck.id),
          onOpenDeckSettings: (deck) => settingsOpened.add(deck.id),
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
    testWidgets('lists each deck with how many terms it holds', (tester) async {
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

    testWidgets('uses the singular for a deck holding one term', (
      tester,
    ) async {
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

    testWidgets('says in words which deck is on the lock screen', (
      tester,
    ) async {
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

    testWidgets('opens the settings for a deck without opening the deck', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        deckRepository: InMemoryDeckRepository(
          initialDecks: [deck('a', 'Spanish basics')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings for Spanish basics'));
      await tester.pumpAndSettle();

      expect(settingsOpened, ['a']);
      // The row's own tap target is unaffected: the shortcut goes straight to
      // the settings rather than through the deck.
      expect(opened, isEmpty);
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

      expect(find.byTooltip('Other is on your lock screen'), findsOneWidget);
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

  testWidgets('offers the pair the app defaults to, already filled in', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create deck'));
    await tester.pumpAndSettle();

    // Prefilled rather than blank, so naming a deck stays the one required
    // step for someone learning the language the app already assumes.
    expect(find.text(languageNameFor(defaultSourceLanguage)), findsOneWidget);
    expect(find.text(languageNameFor(defaultTargetLanguage)), findsOneWidget);
  });

  testWidgets('creates the deck in the pair chosen on the form', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create deck'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deck-name-field')),
      'Travel French',
    );
    await tester.pump();

    await pickLanguage(tester, 'source-language-field', 'French');
    await pickLanguage(tester, 'target-language-field', 'English');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final created = (await createdInto.getAll()).single;

    expect(created.name, 'Travel French');
    expect(created.sourceLanguage, 'fr');
    expect(created.targetLanguage, 'en');
  });

  testWidgets('keeps Create unavailable until the name has content', (
    tester,
  ) async {
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
