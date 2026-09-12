import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/view_models/vocab_list_view_model.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/widgets/vocab_list_screen.dart';

import '../../support/vocab_repository_doubles.dart';

void main() {
  final testDeck = Deck(
    id: 'd1',
    name: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: const Duration(hours: 3),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Future<void> pumpScreen(WidgetTester tester, VocabRepository repository) {
    var counter = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: VocabListScreen(
          title: 'Spanish basics',
          viewModel: VocabListViewModel(
            deck: testDeck,
            repository: repository,
            idGenerator: () => 'id-${++counter}',
          ),
        ),
      ),
    );
  }

  Vocab vocab(String id, String term, String translation) => Vocab(
    id: id,
    deckId: testDeck.id,
    term: term,
    translation: translation,
    sourceLanguage: 'es',
    targetLanguage: 'de',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  testWidgets('shows a progress indicator while entries are loading', (
    tester,
  ) async {
    await pumpScreen(tester, HangingVocabRepository());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('invites the user to add a term when nothing is stored', (
    tester,
  ) async {
    await pumpScreen(tester, InMemoryVocabRepository());
    await tester.pumpAndSettle();

    expect(find.text('No vocabulary yet'), findsOneWidget);
  });

  testWidgets('lists each stored term with its translation', (tester) async {
    await pumpScreen(
      tester,
      InMemoryVocabRepository(
        initialEntries: [vocab('a', 'la casa', 'das Haus')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('la casa'), findsOneWidget);
    expect(find.text('das Haus'), findsOneWidget);
  });

  testWidgets('offers a retry when the repository fails', (tester) async {
    await pumpScreen(tester, FailingVocabRepository());
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('adds a term through the form and shows it in the list', (
    tester,
  ) async {
    await pumpScreen(tester, InMemoryVocabRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add vocabulary'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
    await tester.enterText(
      find.byKey(const Key('translation-field')),
      'das Buch',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('el libro'), findsOneWidget);
    expect(find.text('das Buch'), findsOneWidget);
  });

  Future<void> pumpTwoTerms(WidgetTester tester) async {
    await pumpScreen(
      tester,
      InMemoryVocabRepository(
        initialEntries: [
          vocab('a', 'la casa', 'das Haus'),
          vocab('b', 'el perro', 'der Hund'),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> mark(WidgetTester tester, String term) async {
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(term));
    await tester.pumpAndSettle();
  }

  testWidgets('puts no delete button on a row, so scrolling cannot destroy a '
      'term', (tester) async {
    await pumpTwoTerms(tester);

    expect(find.byTooltip('Delete la casa'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('counts what is marked, so the bar says what will be acted on', (
    tester,
  ) async {
    await pumpTwoTerms(tester);

    await mark(tester, 'la casa');

    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('marks every term from one action', (tester) async {
    await pumpTwoTerms(tester);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
    // The label now offers the other half of the toggle, so the user is never
    // left guessing which state they are in.
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('deletes the marked terms once the question is agreed', (
    tester,
  ) async {
    await pumpTwoTerms(tester);
    await mark(tester, 'la casa');

    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('la casa'), findsNothing);
    expect(find.text('el perro'), findsOneWidget);
  });

  testWidgets('keeps the marked terms when the question is declined', (
    tester,
  ) async {
    await pumpTwoTerms(tester);
    await mark(tester, 'la casa');

    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('la casa'), findsOneWidget);
  });

  testWidgets('edits the one marked term through the form', (tester) async {
    await pumpTwoTerms(tester);
    await mark(tester, 'la casa');

    await tester.tap(find.byTooltip('Edit la casa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('term-field')), 'la casita');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('la casita'), findsOneWidget);
    expect(find.text('la casa'), findsNothing);
  });

  testWidgets('offers no edit while more than one term is marked, because '
      'editing is a single-entry job', (tester) async {
    await pumpTwoTerms(tester);
    await mark(tester, 'la casa');
    await tester.tap(find.text('el perro'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('leaves selection through the close button, dropping the marks', (
    tester,
  ) async {
    await pumpTwoTerms(tester);
    await mark(tester, 'la casa');

    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsNothing);
    expect(find.text('Spanish basics'), findsOneWidget);
  });

  testWidgets('leaves Save unavailable while the form is still blank', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      InMemoryVocabRepository(
        initialEntries: [vocab('a', 'la casa', 'das Haus')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add vocabulary'));
    await tester.pumpAndSettle();

    // The saved list can no longer be endangered by an empty submit, because
    // the submit is not reachable. AddVocabSheet's own tests cover the detail.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
