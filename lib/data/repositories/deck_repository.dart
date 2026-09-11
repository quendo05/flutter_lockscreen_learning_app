import '../../domain/models/deck.dart';

/// The source of truth for decks.
abstract class DeckRepository {
  /// All stored decks, oldest first, so the list order stays stable as decks
  /// are added.
  Future<List<Deck>> getAll();

  /// The deck with [id], or null if nothing is stored under that id.
  Future<Deck?> getById(String id);

  /// Inserts [deck], replacing any deck that already carries the same id.
  Future<void> save(Deck deck);

  /// Removes the deck with [id]. Unknown ids are ignored.
  ///
  /// Says nothing about the terms filed under it: a repository stores what it
  /// is given, and what a deck's terms are worth once the deck is gone is a
  /// decision for whoever is deleting it, not for the store.
  Future<void> delete(String id);
}
