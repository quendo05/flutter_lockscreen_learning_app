import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/data/repositories/settings_repository.dart';
import 'package:nagara/domain/models/deck.dart';

/// The behaviour every [SettingsRepository] implementation must satisfy.
void runSettingsRepositoryContract(
  Future<SettingsRepository> Function() create,
) {
  late SettingsRepository repository;

  setUp(() async => repository = await create());

  group('activeDeckId', () {
    test('starts on the deck every install is guaranteed to have', () async {
      expect(await repository.getActiveDeckId(), defaultDeckId);
    });

    test('returns the deck that was last chosen', () async {
      await repository.setActiveDeckId('travel');

      expect(await repository.getActiveDeckId(), 'travel');
    });

    test('keeps only the most recent choice, not a history of them', () async {
      await repository.setActiveDeckId('travel');
      await repository.setActiveDeckId('food');

      expect(await repository.getActiveDeckId(), 'food');
    });

    test('rejects an empty id, which would point at no deck at all', () async {
      await expectLater(repository.setActiveDeckId(''), throwsArgumentError);
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
