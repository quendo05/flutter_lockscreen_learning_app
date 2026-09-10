import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/main.dart';

void main() {
  testWidgets('opens on the vocabulary list', (tester) async {
    await tester.pumpWidget(
      LockscreenLearningApp(vocabRepository: InMemoryVocabRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('No vocabulary yet'), findsOneWidget);
  });
}
