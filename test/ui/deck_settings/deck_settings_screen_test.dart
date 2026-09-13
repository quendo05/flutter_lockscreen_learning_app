import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/data/repositories/in_memory_deck_repository.dart';
import 'package:nagara/data/repositories/in_memory_settings_repository.dart';
import 'package:nagara/data/repositories/in_memory_vocab_repository.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:nagara/domain/models/vocab.dart';
import 'package:nagara/ui/core/widgets/language_field.dart';
import 'package:nagara/ui/deck_settings/view_models/deck_settings_view_model.dart';
import 'package:nagara/ui/deck_settings/widgets/deck_settings_screen.dart';

void main() {
  final deck = Deck(
    id: 'd1',
    name: 'Spanish basics',
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

  final otherDeck = deck.copyWith(id: 'd2', name: 'Travel');

  late InMemoryDeckRepository repository;
  late InMemoryVocabRepository vocabRepository;
  DeckSettingsOutcome? popped;

  setUp(() {
    repository = InMemoryDeckRepository(initialDecks: [deck]);
    vocabRepository = InMemoryVocabRepository();
    popped = null;
  });

  /// Pushes the screen from a host route, so popping with a result is real.
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Deck>? decks,
    List<Vocab> vocabs = const [],
  }) async {
    repository = InMemoryDeckRepository(initialDecks: decks ?? [deck]);
    vocabRepository = InMemoryVocabRepository(initialEntries: vocabs);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<DeckSettingsOutcome>(
                  MaterialPageRoute<DeckSettingsOutcome>(
                    builder: (_) => DeckSettingsScreen(
                      viewModel: DeckSettingsViewModel(
                        deck: deck,
                        deckRepository: repository,
                        vocabRepository: vocabRepository,
                        settingsRepository: InMemorySettingsRepository(
                          initialActiveDeckId: deck.id,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

  /// Searches one of the language pickers and chooses the match.
  ///
  /// Scoped to the field's own key because both pickers put a text field on
  /// screen, and searched rather than scrolled to because the menu opens at
  /// the current selection.
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

  group('opening', () {
    testWidgets('fills the form in with the deck as it stands', (tester) async {
      await pumpScreen(tester);

      expect(textIn(tester, 'deck-name-field'), 'Spanish basics');
      // Named, not coded: 'es' and 'de' are what get stored, not what the
      // user should have to recognise.
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('German'), findsOneWidget);
      expect(find.text('A new term every 3 hours'), findsOneWidget);
    });

    testWidgets('labels the two languages by what they mean to the user', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Language you are learning'), findsOneWidget);
      expect(find.text('Language you understand'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('stores the edited name and hands the deck back', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('deck-name-field')),
        'Travel Spanish',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect((popped! as DeckSaved).deck.name, 'Travel Spanish');
      expect((await repository.getById('d1'))!.name, 'Travel Spanish');
    });

    testWidgets('stores an edited language pair', (tester) async {
      await pumpScreen(tester);

      await pickLanguage(tester, 'source-language-field', 'French');
      await pickLanguage(tester, 'target-language-field', 'English');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final stored = (await repository.getById('d1'))!;

      expect(stored.sourceLanguage, 'fr');
      expect(stored.targetLanguage, 'en');
    });

    testWidgets('carries a dragged pace through to the deck', (tester) async {
      await pumpScreen(tester);

      // Drag the slider to its far end, which is the widest pace offered.
      await tester.drag(find.byType(Slider), const Offset(500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        (await repository.getById('d1'))!.displayInterval,
        const Duration(hours: maxDisplayIntervalHours),
      );
    });
  });

  group('refusing to save', () {
    testWidgets('keeps Save unavailable while the name is blank', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('deck-name-field')), '');
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('offers no way to blank a language at all', (tester) async {
      await pumpScreen(tester);

      // The pickers are the only way in, and a picker can only report a
      // language it was offering. DeckSettingsViewModel still rejects a blank
      // one; nothing on this screen can produce it.
      expect(find.byType(LanguageField), findsNWidgets(2));
      for (final field in tester.widgetList<LanguageField>(
        find.byType(LanguageField),
      )) {
        expect(field.value, isNotEmpty);
      }
    });

    testWidgets('stays on the screen, so the edit is not lost', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('deck-name-field')), '');
      await tester.pump();

      expect(find.text('Deck settings'), findsOneWidget);
      expect(popped, isNull);
    });
  });

  /// Scrolls down to the destructive section, which sits below the fold on
  /// purpose.
  Future<void> scrollToDelete(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.text('Delete deck'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
  }

  group('deleting the deck', () {
    testWidgets('says why the only deck cannot be deleted, rather than '
        'hiding the option and leaving the user hunting for it', (
      tester,
    ) async {
      await pumpScreen(tester, decks: [deck]);
      await scrollToDelete(tester);

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Delete deck'),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('only deck'), findsOneWidget);
    });

    testWidgets('offers the deletion once there is another deck', (
      tester,
    ) async {
      await pumpScreen(tester, decks: [deck, otherDeck]);
      await scrollToDelete(tester);

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Delete deck'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('asks first, naming the terms that go with it', (tester) async {
      await pumpScreen(
        tester,
        decks: [deck, otherDeck],
        vocabs: [vocab('1', 'd1'), vocab('2', 'd1')],
      );

      await scrollToDelete(tester);
      await tester.tap(find.text('Delete deck'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('2 terms'), findsOneWidget);
    });

    testWidgets('changes nothing when the question is declined', (
      tester,
    ) async {
      await pumpScreen(tester, decks: [deck, otherDeck]);

      await scrollToDelete(tester);
      await tester.tap(find.text('Delete deck'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await repository.getById('d1'), isNotNull);
      expect(find.text('Deck settings'), findsOneWidget);
      expect(popped, isNull);
    });

    testWidgets('removes the deck and its terms once agreed, and closes', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        decks: [deck, otherDeck],
        vocabs: [vocab('1', 'd1'), vocab('2', 'd2')],
      );

      await scrollToDelete(tester);
      await tester.tap(find.text('Delete deck'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await repository.getById('d1'), isNull);
      expect(await vocabRepository.getByDeck('d1'), isEmpty);
      // The other deck is untouched, which is what makes this safe.
      expect(await vocabRepository.getByDeck('d2'), hasLength(1));
      expect(popped, isA<DeckDeleted>());
      expect(find.text('Deck settings'), findsNothing);
    });
  });
}
