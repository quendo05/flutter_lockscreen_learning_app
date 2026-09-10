import '../../domain/models/vocab.dart';
import 'vocab_repository.dart';

/// A [VocabRepository] that keeps everything in memory.
///
/// Used by tests and by the app until the database is wired up. Nothing here
/// survives a restart.
class InMemoryVocabRepository implements VocabRepository {
  InMemoryVocabRepository({List<Vocab> initialEntries = const []}) {
    for (final entry in initialEntries) {
      _entriesById[entry.id] = entry;
    }
  }

  final Map<String, Vocab> _entriesById = {};

  @override
  Future<List<Vocab>> getByDeck(String deckId) async {
    final entries = _entriesById.values
        .where((entry) => entry.deckId == deckId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<Vocab?> getById(String id) async => _entriesById[id];

  @override
  Future<void> save(Vocab vocab) async {
    _entriesById[vocab.id] = vocab;
  }

  @override
  Future<void> delete(String id) async {
    _entriesById.remove(id);
  }
}
