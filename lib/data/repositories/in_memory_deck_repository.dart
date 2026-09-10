import '../../domain/models/deck.dart';
import 'deck_repository.dart';

/// A [DeckRepository] that keeps everything in memory.
///
/// Used by tests and by the web build. Nothing here survives a restart.
class InMemoryDeckRepository implements DeckRepository {
  InMemoryDeckRepository({List<Deck> initialDecks = const []}) {
    for (final deck in initialDecks) {
      _decksById[deck.id] = deck;
    }
  }

  final Map<String, Deck> _decksById = {};

  @override
  Future<List<Deck>> getAll() async {
    final decks = _decksById.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return decks;
  }

  @override
  Future<Deck?> getById(String id) async => _decksById[id];

  @override
  Future<void> save(Deck deck) async {
    _decksById[deck.id] = deck;
  }
}
