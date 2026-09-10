import '../../domain/models/deck.dart';

/// The source of truth for decks.
///
/// There is deliberately no delete: nothing asks for it yet, and removing a
/// deck raises the question of what happens to the terms inside it.
abstract class DeckRepository {
  /// All stored decks, oldest first, so the list order stays stable as decks
  /// are added.
  Future<List<Deck>> getAll();

  /// The deck with [id], or null if nothing is stored under that id.
  Future<Deck?> getById(String id);

  /// Inserts [deck], replacing any deck that already carries the same id.
  Future<void> save(Deck deck);
}
