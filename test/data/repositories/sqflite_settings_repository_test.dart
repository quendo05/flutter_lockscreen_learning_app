import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/sqflite_settings_repository.dart';
import 'package:lockscreen_learning_app/data/services/app_database.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'settings_repository_contract.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqfliteSettingsRepository', () {
    runSettingsRepositoryContract(() async {
      return SqfliteSettingsRepository(await AppDatabase.openInMemory());
    });
  });

  test('survives closing and reopening the database', () async {
    final tempDir = await Directory.systemTemp.createTemp('settings_test');
    addTearDown(() => tempDir.delete(recursive: true));
    final path = p.join(tempDir.path, 'vocab.db');

    final first = await AppDatabase.open(path);
    await SqfliteSettingsRepository(first).setActiveDeckId('travel');
    await first.close();

    final second = await AppDatabase.open(path);
    final active = await SqfliteSettingsRepository(second).getActiveDeckId();
    await second.close();

    // The whole point of this implementation: the choice outlives the process.
    expect(active, 'travel');
  });

  group('upgrading from schema version 3', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('settings_migration');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('starts an upgraded install on the default deck', () async {
      final path = p.join(tempDir.path, 'vocab.db');

      // Version 3 had no settings table at all.
      final old = await openDatabase(
        path,
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE decks (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              sourceLanguage TEXT NOT NULL,
              targetLanguage TEXT NOT NULL,
              displayIntervalMinutes INTEGER NOT NULL,
              createdAt INTEGER NOT NULL
            )
          ''');
        },
      );
      await old.close();

      final database = await AppDatabase.open(path);
      final active = await SqfliteSettingsRepository(database)
          .getActiveDeckId();
      await database.close();

      expect(active, defaultDeckId);
    });
  });
}
