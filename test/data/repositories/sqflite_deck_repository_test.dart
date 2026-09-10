import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/sqflite_deck_repository.dart';
import 'package:lockscreen_learning_app/data/services/app_database.dart';
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
}
