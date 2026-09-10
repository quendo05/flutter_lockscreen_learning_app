import 'package:sqflite/sqflite.dart';

import '../../domain/models/vocab.dart';
import 'vocab_repository.dart';

/// A [VocabRepository] backed by SQLite, so entries survive a restart.
class SqfliteVocabRepository implements VocabRepository {
  SqfliteVocabRepository._(this._database);

  final Database _database;

  static const _table = 'vocabs';
  static const _schemaVersion = 1;

  /// Opens the database stored at [path], creating it if necessary.
  static Future<SqfliteVocabRepository> openAt(String path) async {
    final database = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _createSchema,
    );
    return SqfliteVocabRepository._(database);
  }

  /// Opens a throwaway database that lives only in memory. Used by tests.
  ///
  /// sqflite keeps a single database per path, and the in-memory path is no
  /// exception, so any previous one is discarded first to guarantee a caller
  /// really gets an empty database.
  static Future<SqfliteVocabRepository> openInMemory() async {
    await deleteDatabase(inMemoryDatabasePath);
    return openAt(inMemoryDatabasePath);
  }

  /// Column names and types mirror [Vocab.toMap], which is why rows can be
  /// handed to [Vocab.fromMap] unchanged.
  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY NOT NULL,
        term TEXT NOT NULL,
        translation TEXT NOT NULL,
        sourceLanguage TEXT NOT NULL,
        targetLanguage TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        lastShownAt INTEGER,
        timesShown INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Matches the ordering the scheduler asks for, so picking the next terms
    // stays cheap as the collection grows.
    await db.execute('''
      CREATE INDEX idx_${_table}_practice
        ON $_table (lastShownAt, timesShown)
    ''');
  }

  @override
  Future<List<Vocab>> getAll() async {
    final rows = await _database.query(_table, orderBy: 'createdAt DESC');
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

  /// Releases the underlying database handle.
  Future<void> close() => _database.close();
}
