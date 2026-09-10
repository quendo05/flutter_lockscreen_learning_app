import 'package:sqflite/sqflite.dart';

import '../../domain/models/vocab.dart';
import '../services/app_database.dart';
import 'vocab_repository.dart';

/// A [VocabRepository] backed by SQLite, so entries survive a restart.
///
/// Takes an already-open database because [AppDatabase] owns the schema and
/// the deck repository shares the same connection.
class SqfliteVocabRepository implements VocabRepository {
  const SqfliteVocabRepository(this._database);

  final Database _database;

  static const _table = AppDatabase.vocabsTable;

  @override
  Future<List<Vocab>> getAll() async {
    final rows = await _database.query(_table, orderBy: 'createdAt DESC');
    return rows.map(Vocab.fromMap).toList();
  }

  @override
  Future<List<Vocab>> getByDeck(String deckId) async {
    final rows = await _database.query(
      _table,
      where: 'deckId = ?',
      whereArgs: [deckId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Vocab.fromMap).toList();
  }

  @override
  Future<Vocab?> getById(String id) async {
    final rows = await _database.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Vocab.fromMap(rows.single);
  }

  @override
  Future<void> save(Vocab vocab) async {
    await _database.insert(
      _table,
      vocab.toMap(),
      // Saving an existing id is an update, matching the repository contract.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
