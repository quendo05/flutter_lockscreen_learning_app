import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_settings_repository.dart';

void main() {
  late InMemorySettingsRepository repository;

  setUp(() => repository = InMemorySettingsRepository());

  group('displayInterval', () {
    test('defaults to three hours before the user has chosen anything', () async {
      expect(await repository.getDisplayInterval(), const Duration(hours: 3));
    });

    test('returns the interval that was last set', () async {
      await repository.setDisplayInterval(const Duration(hours: 6));

      expect(await repository.getDisplayInterval(), const Duration(hours: 6));
    });

    test('accepts an explicit default supplied at construction', () async {
      final custom = InMemorySettingsRepository(
        initialInterval: const Duration(hours: 12),
      );

      expect(await custom.getDisplayInterval(), const Duration(hours: 12));
    });

    test('rejects a zero interval, which would schedule infinite reminders', () {
      expect(
        () => repository.setDisplayInterval(Duration.zero),
        throwsArgumentError,
      );
    });

    test('rejects a negative interval', () {
      expect(
        () => repository.setDisplayInterval(const Duration(hours: -1)),
        throwsArgumentError,
      );
    });

    test('leaves the stored interval unchanged after a rejected value', () async {
      try {
        await repository.setDisplayInterval(Duration.zero);
      } on ArgumentError {
        // Expected — we only care about the state afterwards.
      }

      expect(await repository.getDisplayInterval(), const Duration(hours: 3));
    });
  });
}
