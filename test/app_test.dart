import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/main.dart';

void main() {
  testWidgets('opens on the home screen', (tester) async {
    await tester.pumpWidget(
      LockscreenLearningApp(
        vocabRepository: InMemoryVocabRepository(),
        deckRepository: InMemoryDeckRepository(
          initialDecks: [
            Deck(
              id: defaultDeckId,
              name: defaultDeckName,
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          ],
        ),
        settingsRepository: InMemorySettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LockScreenVocab'), findsOneWidget);
    expect(find.text('Nothing on your lock screen yet'), findsOneWidget);
  });
}
