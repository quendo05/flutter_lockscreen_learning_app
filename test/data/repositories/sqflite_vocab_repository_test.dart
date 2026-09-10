import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/sqflite_vocab_repository.dart';
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
    runVocabRepositoryContract(SqfliteVocabRepository.openInMemory);
  });

  group('persistence', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vocab_db_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('still has the entries after closing and reopening the file', () async {
      final path = p.join(tempDir.path, 'vocab.db');

      final first = await SqfliteVocabRepository.openAt(path);
      await first.save(contractVocab('a').copyWith(timesShown: 2));
      await first.close();

      final second = await SqfliteVocabRepository.openAt(path);
      final reloaded = await second.getAll();
      await second.close();

      expect(reloaded.single.id, 'a');
      expect(reloaded.single.timesShown, 2);
    });

    test('writes an actual file to disk', () async {
      final path = p.join(tempDir.path, 'vocab.db');

      final repository = await SqfliteVocabRepository.openAt(path);
      await repository.save(contractVocab('a'));
      await repository.close();

      expect(File(path).existsSync(), isTrue);
    });
  });
}
