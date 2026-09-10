/// User preferences that control how often a new term is surfaced.
abstract class SettingsRepository {
  /// How long to wait between two lock screen terms.
  Future<Duration> getDisplayInterval();

  /// Stores [interval]. Throws [ArgumentError] if it is not positive.
  Future<void> setDisplayInterval(Duration interval);
}
