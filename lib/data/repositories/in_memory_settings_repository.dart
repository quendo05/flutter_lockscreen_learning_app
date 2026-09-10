import 'settings_repository.dart';

/// Default cadence: a new term every three hours.
const kDefaultDisplayInterval = Duration(hours: 3);

/// A [SettingsRepository] that keeps preferences in memory.
///
/// Used by tests and by the app until preferences are persisted. Nothing here
/// survives a restart.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({
    Duration initialInterval = kDefaultDisplayInterval,
  }) : _displayInterval = initialInterval;

  Duration _displayInterval;

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
}
