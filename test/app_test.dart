import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/data/repositories/in_memory_deck_repository.dart';
import 'package:nagara/data/repositories/in_memory_settings_repository.dart';
import 'package:nagara/data/repositories/in_memory_vocab_repository.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:nagara/main.dart';

void main() {
  testWidgets('opens on the home screen', (tester) async {
    await tester.pumpWidget(
      LockscreenLearningApp(
        vocabRepository: InMemoryVocabRepository(),
        deckRepository: InMemoryDeckRepository(
          initialDecks: [Deck.initial(createdAt: DateTime.utc(2026, 1, 1))],
        ),
        settingsRepository: InMemorySettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nagara'), findsOneWidget);
    expect(find.text('Nothing on your lock screen yet'), findsOneWidget);
  });
}
