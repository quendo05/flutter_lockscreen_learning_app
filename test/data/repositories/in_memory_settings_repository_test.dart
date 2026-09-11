import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';

import 'settings_repository_contract.dart';

void main() {
  group('InMemorySettingsRepository', () {
    runSettingsRepositoryContract(() async => InMemorySettingsRepository());
  });

  test('accepts an explicit starting deck', () async {
    final repository = InMemorySettingsRepository(
      initialActiveDeckId: 'travel',
    );

    expect(await repository.getActiveDeckId(), 'travel');
  });
}
