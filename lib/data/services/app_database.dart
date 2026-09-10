import 'package:sqflite/sqflite.dart';

import '../../domain/models/deck.dart';

/// Owns the SQLite schema and its migrations.
///
/// Both repositories share one open [Database], so the schema cannot live
/// inside either of them.
class AppDatabase {
  const AppDatabase._();

  static const decksTable = 'decks';
  static const vocabsTable = 'vocabs';

  /// Bump this and add an [_upgrade] branch whenever the schema changes.
  static const schemaVersion = 2;

  static Future<Database> open(String path) => openDatabase(
        path,
        version: schemaVersion,
        onCreate: _create,
        onUpgrade: _upgrade,
      );

  /// A throwaway database that lives only in memory. Used by tests.
  ///
  /// sqflite keeps one database per path, the in-memory path included, so any
  /// previous one is discarded to guarantee the caller gets an empty database.
  static Future<Database> openInMemory() async {
    await deleteDatabase(inMemoryDatabasePath);
    return open(inMemoryDatabasePath);
  }

  static Future<void> _create(Database db, int version) async {
    await _createDecksTable(db);
    await _insertDefaultDeck(db);

    await db.execute('''
      CREATE TABLE $vocabsTable (
        id TEXT PRIMARY KEY NOT NULL,
        deckId TEXT NOT NULL,
        term TEXT NOT NULL,
        translation TEXT NOT NULL,
        sourceLanguage TEXT NOT NULL,
        targetLanguage TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        lastShownAt INTEGER,
        timesShown INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createVocabIndexes(db);
  }

  /// Version 1 had a single flat table of terms and no notion of decks.
  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) {
      await _createDecksTable(db);
      await _insertDefaultDeck(db);

      // The column default backfills every pre-existing row, so terms saved
      // before decks existed end up in the default deck rather than orphaned.
      await db.execute('''
        ALTER TABLE $vocabsTable
          ADD COLUMN deckId TEXT NOT NULL DEFAULT '$defaultDeckId'
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_${vocabsTable}_deck
          ON $vocabsTable (deckId)
      ''');
    }
  }

  static Future<void> _createDecksTable(Database db) => db.execute('''
        CREATE TABLE $decksTable (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');

  /// Every install has at least one deck, so there is always somewhere to save.
  static Future<void> _insertDefaultDeck(Database db) => db.insert(
        decksTable,
        Deck.initial(createdAt: DateTime.now().toUtc()).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  static Future<void> _createVocabIndexes(Database db) async {
    // Matches the ordering the scheduler asks for, so picking the next terms
    // stays cheap as the collection grows.
    await db.execute('''
      CREATE INDEX idx_${vocabsTable}_practice
        ON $vocabsTable (lastShownAt, timesShown)
    ''');
    await db.execute('''
      CREATE INDEX idx_${vocabsTable}_deck ON $vocabsTable (deckId)
    ''');
  }
}
