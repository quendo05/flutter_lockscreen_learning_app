import '../../domain/models/vocab.dart';

/// The source of truth for vocabulary entries.
///
/// Every method is asynchronous because the real implementation talks to a
/// database. Keeping the contract async from the start means swapping the
/// in-memory implementation for a persistent one does not ripple through the
/// view models.
abstract class VocabRepository {
  /// The entries belonging to [deckId], newest first.
  Future<List<Vocab>> getByDeck(String deckId);

  /// The entry with [id], or null if nothing is stored under that id.
  Future<Vocab?> getById(String id);

  /// Inserts [vocab], replacing any entry that already carries the same id.
  Future<void> save(Vocab vocab);

  /// Removes the entry with [id]. Unknown ids are ignored.
  Future<void> delete(String id);

  /// Removes every entry filed under [deckId]. A deck holding nothing is
  /// ignored.
  ///
  /// One call rather than a delete per entry so the database can clear a deck
  /// in a single statement, and so a half-finished loop cannot leave a deck
  /// partly emptied.
  Future<void> deleteByDeck(String deckId);
}
