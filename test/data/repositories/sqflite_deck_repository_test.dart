import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/config/defaults.dart';
import 'package:nagara/data/repositories/sqflite_deck_repository.dart';
import 'package:nagara/data/services/app_database.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'deck_repository_contract.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqfliteDeckRepository', () {
    // The default deck is created by the schema, so each contract run starts
    // from a database that already holds it. Clearing keeps the shared
    // contract expectations about counts honest.
    runDeckRepositoryContract(() async {
      final database = await AppDatabase.openInMemory();
      await database.delete(AppDatabase.decksTable);
      return SqfliteDeckRepository(database);
    });
  });

  test('reads the default deck the schema created', () async {
    final repository = SqfliteDeckRepository(await AppDatabase.openInMemory());

    expect((await repository.getAll()).single.name, 'My vocabulary');
  });

  group('upgrading from schema version 2', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('deck_migration_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    /// Recreates version 2: decks existed, but a deck did not yet own the
    /// language pair or the interval.
    Future<void> writeVersion2Database(String path) async {
      final db = await openDatabase(
        path,
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE decks (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              createdAt INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE vocabs (
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
        },
      );
      await db.insert('decks', {
        'id': 'existing',
        'name': 'Kept deck',
        'createdAt': DateTime.utc(2026, 2, 2).millisecondsSinceEpoch,
      });
      await db.close();
    }

    test('keeps decks that existed before they owned their settings', () async {
      final path = p.join(tempDir.path, 'vocab.db');
      await writeVersion2Database(path);

      final database = await AppDatabase.open(path);
      final decks = await SqfliteDeckRepository(database).getAll();
      await database.close();

      expect(decks.single.name, 'Kept deck');
      expect(decks.single.createdAt, DateTime.utc(2026, 2, 2));
    });

    test('gives them the pace and pair the app previously assumed', () async {
      final path = p.join(tempDir.path, 'vocab.db');
      await writeVersion2Database(path);

      final database = await AppDatabase.open(path);
      final deck = (await SqfliteDeckRepository(database).getAll()).single;
      await database.close();

      expect(deck.displayInterval, defaultDisplayInterval);
      expect(deck.sourceLanguage, defaultSourceLanguage);
      expect(deck.targetLanguage, defaultTargetLanguage);
    });
  });

  test('a fresh deck carries the study settings the schema wrote', () async {
    final repository = SqfliteDeckRepository(await AppDatabase.openInMemory());

    final seeded = (await repository.getAll()).single;

    expect(seeded, Deck.initial(createdAt: seeded.createdAt));
  });
}
