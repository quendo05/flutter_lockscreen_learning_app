import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/sqflite_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/services/app_database.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'vocab_repository_contract.dart';

void main() {
  // Tests run on the desktop VM, which has no bundled SQLite; the ffi factory
  // supplies one so the database layer is testable without a device.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqfliteVocabRepository', () {
    runVocabRepositoryContract(
      () async => SqfliteVocabRepository(await AppDatabase.openInMemory()),
    );
  });

  group('with a database file', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vocab_db_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('still has the entries after closing and reopening', () async {
      final path = p.join(tempDir.path, 'vocab.db');

      final first = await AppDatabase.open(path);
      await SqfliteVocabRepository(first).save(
        contractVocab('a').copyWith(timesShown: 2),
      );
      await first.close();

      final second = await AppDatabase.open(path);
      final reloaded = await SqfliteVocabRepository(second).getAll();
      await second.close();

      expect(reloaded.single.id, 'a');
      expect(reloaded.single.timesShown, 2);
    });

    test('writes an actual file to disk', () async {
      final path = p.join(tempDir.path, 'vocab.db');

      final database = await AppDatabase.open(path);
      await SqfliteVocabRepository(database).save(contractVocab('a'));
      await database.close();

      expect(File(path).existsSync(), isTrue);
    });

    group('upgrading from schema version 1', () {
      /// Recreates the shape version 1 shipped with: no decks, no deckId.
      Future<void> writeVersion1Database(String path) async {
        final db = await openDatabase(
          path,
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE vocabs (
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
          },
        );
        await db.insert('vocabs', {
          'id': 'existing',
          'term': 'la biblioteca',
          'translation': 'die Bibliothek',
          'sourceLanguage': 'es',
          'targetLanguage': 'de',
          'createdAt': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
          'lastShownAt': null,
          'timesShown': 3,
        });
        await db.close();
      }

      test('keeps terms that were saved before decks existed', () async {
        final path = p.join(tempDir.path, 'vocab.db');
        await writeVersion1Database(path);

        final database = await AppDatabase.open(path);
        final entries = await SqfliteVocabRepository(database).getAll();
        await database.close();

        expect(entries, hasLength(1));
        expect(entries.single.term, 'la biblioteca');
        expect(entries.single.timesShown, 3);
      });

      test('files those terms into the default deck', () async {
        final path = p.join(tempDir.path, 'vocab.db');
        await writeVersion1Database(path);

        final database = await AppDatabase.open(path);
        final entries = await SqfliteVocabRepository(database).getAll();
        await database.close();

        expect(entries.single.deckId, defaultDeckId);
      });

      test('creates the default deck so the terms are reachable', () async {
        final path = p.join(tempDir.path, 'vocab.db');
        await writeVersion1Database(path);

        final database = await AppDatabase.open(path);
        final decks = await database.query(AppDatabase.decksTable);
        await database.close();

        expect(decks, hasLength(1));
        expect(decks.single['id'], defaultDeckId);
        expect(decks.single['name'], defaultDeckName);
      });
    });
  });

  test('a fresh database already contains the default deck', () async {
    final database = await AppDatabase.openInMemory();

    final decks = await database.query(AppDatabase.decksTable);

    expect(decks.single['id'], defaultDeckId);
  });
}
