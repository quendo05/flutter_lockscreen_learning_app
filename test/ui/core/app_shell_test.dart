import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/ui/core/widgets/app_shell.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    InMemoryVocabRepository? repository,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          vocabRepository: repository ?? InMemoryVocabRepository(),
          settingsRepository: InMemorySettingsRepository(),
        ),
      ),
    );
  }

  testWidgets('opens on the home screen', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.text('LockScreenVocab'), findsOneWidget);
    expect(find.text('Vocabulary'), findsNothing);
  });

  testWidgets('offers both destinations in the navigation bar', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    // The label in the navigation bar, while the vocabulary screen is not up.
    expect(find.text('Words'), findsOneWidget);
  });

  testWidgets('shows the vocabulary list when its destination is chosen',
      (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Words'));
    await tester.pumpAndSettle();

    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.byTooltip('Add vocabulary'), findsOneWidget);
  });

  testWidgets('returns to the home screen from the vocabulary list',
      (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Words'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('LockScreenVocab'), findsOneWidget);
  });

  testWidgets('sends the empty-state action through to the vocabulary list',
      (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your first term'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add vocabulary'), findsOneWidget);
  });

  testWidgets('refreshes the home summary after a term is added elsewhere',
      (tester) async {
    final repository = InMemoryVocabRepository();
    await pumpShell(tester, repository: repository);
    await tester.pumpAndSettle();

    // Add a term through the vocabulary tab, then come back to home.
    await tester.tap(find.text('Words'));
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
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('1 term saved'), findsOneWidget);
    expect(find.text('Nothing on your lock screen yet'), findsNothing);
  });
}
