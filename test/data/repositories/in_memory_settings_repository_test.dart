import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';

void main() {
  late InMemorySettingsRepository repository;

  setUp(() => repository = InMemorySettingsRepository());

  group('activeDeckId', () {
    test('starts on the deck every install is guaranteed to have', () async {
      expect(await repository.getActiveDeckId(), defaultDeckId);
    });

    test('returns the deck that was last chosen', () async {
      await repository.setActiveDeckId('travel');

      expect(await repository.getActiveDeckId(), 'travel');
    });

    test('accepts an explicit starting deck', () async {
      final custom = InMemorySettingsRepository(initialActiveDeckId: 'travel');

      expect(await custom.getActiveDeckId(), 'travel');
    });

    test('rejects an empty id, which would point at no deck at all', () {
      expect(() => repository.setActiveDeckId(''), throwsArgumentError);
    });

    test('leaves the stored deck unchanged after a rejected value', () async {
      try {
        await repository.setActiveDeckId('');
      } on ArgumentError {
        // Expected — only the state afterwards matters here.
      }

      expect(await repository.getActiveDeckId(), defaultDeckId);
    });
  });
}
