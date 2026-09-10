import '../../domain/models/deck.dart';
import 'settings_repository.dart';

/// A [SettingsRepository] that keeps preferences in memory.
///
/// Used by tests and by the app until preferences are persisted. Nothing here
/// survives a restart.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({String initialActiveDeckId = defaultDeckId})
    : _activeDeckId = initialActiveDeckId;

  String _activeDeckId;

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
