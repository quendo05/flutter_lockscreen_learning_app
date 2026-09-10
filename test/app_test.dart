import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/main.dart';

void main() {
  testWidgets('opens on the home screen', (tester) async {
    await tester.pumpWidget(
      LockscreenLearningApp(
        vocabRepository: InMemoryVocabRepository(),
        settingsRepository: InMemorySettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LockScreenVocab'), findsOneWidget);
    expect(find.text('Nothing on your lock screen yet'), findsOneWidget);
  });
}
