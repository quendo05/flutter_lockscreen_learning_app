import '../../config/defaults.dart';
import '../../domain/models/deck.dart';
import 'settings_repository.dart';

/// A [SettingsRepository] that keeps preferences in memory.
///
/// Used by tests and by the app until preferences are persisted. Nothing here
/// survives a restart.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({
    Duration initialInterval = defaultDisplayInterval,
    String initialActiveDeckId = defaultDeckId,
  })  : _displayInterval = initialInterval,
        _activeDeckId = initialActiveDeckId;

  Duration _displayInterval;
  String _activeDeckId;

  @override
  Future<Duration> getDisplayInterval() async => _displayInterval;

  @override
  Future<void> setDisplayInterval(Duration interval) async {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(
        interval,
        'interval',
        'Display interval must be positive.',
      );
    }
    _displayInterval = interval;
  }

  @override
  Future<String> getActiveDeckId() async => _activeDeckId;

  @override
  Future<void> setActiveDeckId(String deckId) async {
    if (deckId.isEmpty) {
      throw ArgumentError.value(deckId, 'deckId', 'Must not be empty.');
    }
    _activeDeckId = deckId;
  }
}
