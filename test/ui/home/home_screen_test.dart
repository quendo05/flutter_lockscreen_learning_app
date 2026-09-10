import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/home/view_models/home_view_model.dart';
import 'package:lockscreen_learning_app/ui/home/widgets/home_screen.dart';

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

void main() {
  var browseTaps = 0;

  setUp(() => browseTaps = 0);

  Vocab vocab(String id, String term, String translation) => Vocab(
        id: id,
        term: term,
        translation: translation,
        sourceLanguage: 'es',
        targetLanguage: 'de',
        createdAt: DateTime.utc(2026, 1, 1),
      );

  Future<void> pumpHome(WidgetTester tester, VocabRepository repository) {
    return tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          viewModel: HomeViewModel(
            vocabRepository: repository,
            settingsRepository: InMemorySettingsRepository(),
            clock: () => DateTime(2026, 7, 1, 9),
          ),
          onBrowseVocabulary: () => browseTaps++,
        ),
      ),
    );
  }

  testWidgets('names the app in the header', (tester) async {
    await pumpHome(tester, InMemoryVocabRepository());
    await tester.pumpAndSettle();

    expect(find.text('LockScreenVocab'), findsOneWidget);
  });

  group('with nothing saved', () {
    testWidgets('explains that there is nothing to show yet', (tester) async {
      await pumpHome(tester, InMemoryVocabRepository());
      await tester.pumpAndSettle();

      expect(find.text('Nothing on your lock screen yet'), findsOneWidget);
    });

    testWidgets('offers a way through to the vocabulary list', (tester) async {
      await pumpHome(tester, InMemoryVocabRepository());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add your first term'));
      await tester.pumpAndSettle();

      expect(browseTaps, 1);
    });
  });

  group('with vocabulary saved', () {
    testWidgets('shows the term that is up next with its translation',
        (tester) async {
      await pumpHome(
        tester,
        InMemoryVocabRepository(
          initialEntries: [vocab('a', 'la biblioteca', 'die Bibliothek')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('la biblioteca'), findsOneWidget);
      expect(find.text('die Bibliothek'), findsOneWidget);
    });

    testWidgets('states how many terms are saved', (tester) async {
      await pumpHome(
        tester,
        InMemoryVocabRepository(
          initialEntries: [
            vocab('a', 'uno', 'eins'),
            vocab('b', 'dos', 'zwei'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 terms saved'), findsOneWidget);
    });

    testWidgets('uses the singular for a lone term', (tester) async {
      await pumpHome(
        tester,
        InMemoryVocabRepository(
          initialEntries: [vocab('a', 'uno', 'eins')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 term saved'), findsOneWidget);
    });
  });

  testWidgets('offers a retry when the store cannot be read', (tester) async {
    await pumpHome(tester, _FailingVocabRepository());
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Nothing on your lock screen yet'), findsNothing);
  });
}
