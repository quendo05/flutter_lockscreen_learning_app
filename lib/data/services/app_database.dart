import 'package:sqflite/sqflite.dart';

import '../../config/defaults.dart';
import '../../domain/models/deck.dart';

/// Owns the SQLite schema and its migrations.
///
/// Both repositories share one open [Database], so the schema cannot live
/// inside either of them.
class AppDatabase {
  const AppDatabase._();

  static const decksTable = 'decks';
  static const vocabsTable = 'vocabs';
  static const settingsTable = 'settings';

  /// The only row [settingsTable] ever holds. What it stores belongs to
  /// the install rather than to a user, so a second row would mean
  /// nothing; the CHECK constraint makes that structural.
  static const settingsRowId = 1;

  /// Bump this and add an [_upgrade] branch whenever the schema changes.
  static const schemaVersion = 4;

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
    await _createSettingsTable(db);
  }

  /// Version 1 had a single flat table of terms and no notion of decks.
  /// Version 2 had decks, but how a deck was studied lived in global settings.
  ///
  /// Each step below spells out the shape it produces rather than calling the
  /// helpers [_createDecksTable] and [_insertDefaultDeck]. Those describe the
  /// current schema and move on with it, whereas a migration has to keep
  /// producing the shape that existed when it was written — otherwise the step
  /// after it tries to add columns that are already there.
  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) {
      // The decks table as it stood at version 2.
      await db.execute('''
        CREATE TABLE $decksTable (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
      await db.insert(decksTable, {
        'id': defaultDeckId,
        'name': defaultDeckName,
        'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

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

    if (from < 3) {
      // How a deck is studied moves out of global settings and onto the deck
      // itself. The column defaults give every existing deck the pair and pace
      // the app previously assumed for all of them, so nothing changes for the
      // user until they open a deck's settings.
      await db.execute('''
        ALTER TABLE $decksTable ADD COLUMN sourceLanguage TEXT NOT NULL
          DEFAULT '$defaultSourceLanguage'
      ''');
      await db.execute('''
        ALTER TABLE $decksTable ADD COLUMN targetLanguage TEXT NOT NULL
          DEFAULT '$defaultTargetLanguage'
      ''');
      await db.execute('''
        ALTER TABLE $decksTable ADD COLUMN displayIntervalMinutes INTEGER
          NOT NULL DEFAULT ${defaultDisplayInterval.inMinutes}
      ''');
    }

    if (from < 4) {
      // Which deck feeds the lock screen was previously forgotten on every
      // launch. Seeded with the deck the app fell back to anyway, so an
      // upgraded install carries on pointing where it already pointed.
      await db.execute('''
        CREATE TABLE $settingsTable (
          id INTEGER PRIMARY KEY CHECK (id = $settingsRowId),
          activeDeckId TEXT NOT NULL
        )
      ''');
      await db.insert(settingsTable, {
        'id': settingsRowId,
        'activeDeckId': defaultDeckId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// The settings row, seeded on creation so a read never has to cope with
  /// its absence and every write is an update of something that exists.
  static Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $settingsTable (
        id INTEGER PRIMARY KEY CHECK (id = $settingsRowId),
        activeDeckId TEXT NOT NULL
      )
    ''');
    await db.insert(settingsTable, {
      'id': settingsRowId,
      'activeDeckId': defaultDeckId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> _createDecksTable(Database db) => db.execute('''
        CREATE TABLE $decksTable (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          sourceLanguage TEXT NOT NULL,
          targetLanguage TEXT NOT NULL,
          displayIntervalMinutes INTEGER NOT NULL,
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
