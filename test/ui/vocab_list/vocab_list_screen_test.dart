import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/view_models/vocab_list_view_model.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/widgets/vocab_list_screen.dart';

class _FailingVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getAll() async => throw Exception('offline');
  @override
  Future<Vocab?> getById(String id) async => throw Exception('offline');
  @override
  Future<void> save(Vocab vocab) async => throw Exception('offline');
  @override
  Future<void> delete(String id) async => throw Exception('offline');
}

/// Never completes, so the screen stays in its loading state.
class _HangingVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getAll() => Completer<List<Vocab>>().future;
  @override
  Future<Vocab?> getById(String id) async => null;
  @override
  Future<void> save(Vocab vocab) async {}
  @override
  Future<void> delete(String id) async {}
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, VocabRepository repository) {
    var counter = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: VocabListScreen(
          viewModel: VocabListViewModel(
            repository: repository,
            idGenerator: () => 'id-${++counter}',
          ),
        ),
      ),
    );
  }

  Vocab vocab(String id, String term, String translation) => Vocab(
        id: id,
        term: term,
        translation: translation,
        sourceLanguage: 'es',
        targetLanguage: 'de',
        createdAt: DateTime.utc(2026, 1, 1),
      );

  testWidgets('shows a progress indicator while entries are loading',
      (tester) async {
    await pumpScreen(tester, _HangingVocabRepository());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('invites the user to add a term when nothing is stored',
      (tester) async {
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
    await pumpScreen(tester, _FailingVocabRepository());
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('adds a term through the form and shows it in the list',
      (tester) async {
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

  testWidgets('removes a term when its delete button is used', (tester) async {
    await pumpScreen(
      tester,
      InMemoryVocabRepository(
        initialEntries: [vocab('a', 'la casa', 'das Haus')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete la casa'));
    await tester.pumpAndSettle();

    expect(find.text('la casa'), findsNothing);
    expect(find.text('No vocabulary yet'), findsOneWidget);
  });

  testWidgets('leaves Save unavailable while the form is still blank',
      (tester) async {
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
