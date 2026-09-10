/// The preferences that belong to the app rather than to a deck.
///
/// How often terms appear and which languages they are in are properties of a
/// deck, so they live on [Deck]. What remains global is the one thing that
/// cannot: which single deck is currently feeding the lock screen.
abstract class SettingsRepository {
  /// The deck currently feeding the lock screen.
  Future<String> getActiveDeckId();

  /// Chooses which deck feeds the lock screen.
  Future<void> setActiveDeckId(String deckId);
}
