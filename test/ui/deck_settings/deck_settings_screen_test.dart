import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/ui/deck_settings/view_models/deck_settings_view_model.dart';
import 'package:lockscreen_learning_app/ui/deck_settings/widgets/deck_settings_screen.dart';

void main() {
  final deck = Deck(
    id: 'd1',
    name: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: const Duration(hours: 3),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  late InMemoryDeckRepository repository;
  Deck? popped;

  setUp(() {
    repository = InMemoryDeckRepository(initialDecks: [deck]);
    popped = null;
  });

  /// Pushes the screen from a host route, so popping with a result is real.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<Deck>(
                  MaterialPageRoute<Deck>(
                    builder: (_) => DeckSettingsScreen(
                      viewModel: DeckSettingsViewModel(
                        deck: deck,
                        repository: repository,
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

  group('opening', () {
    testWidgets('fills the form in with the deck as it stands', (tester) async {
      await pumpScreen(tester);

      expect(textIn(tester, 'deck-name-field'), 'Spanish basics');
      expect(textIn(tester, 'source-language-field'), 'es');
      expect(textIn(tester, 'target-language-field'), 'de');
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

      expect(popped?.name, 'Travel Spanish');
      expect((await repository.getById('d1'))!.name, 'Travel Spanish');
    });

    testWidgets('stores an edited language pair', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('source-language-field')),
        'fr',
      );
      await tester.enterText(
        find.byKey(const Key('target-language-field')),
        'en',
      );
      await tester.pump();
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

    testWidgets('keeps Save unavailable while a language is blank', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('source-language-field')),
        '',
      );
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('stays on the screen, so the edit is not lost', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('deck-name-field')), '');
      await tester.pump();

      expect(find.text('Deck settings'), findsOneWidget);
      expect(popped, isNull);
    });
  });
}
