import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';

Vocab contractVocab(String id, {DateTime? createdAt}) => Vocab(
      id: id,
      term: 'term-$id',
      translation: 'translation-$id',
      sourceLanguage: 'es',
      targetLanguage: 'de',
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    );

/// The behaviour every [VocabRepository] implementation must satisfy.
///
/// Both the in-memory and the sqflite repository run this same suite, so the
/// two cannot silently drift apart — which is what makes swapping them safe.
void runVocabRepositoryContract(Future<VocabRepository> Function() create) {
  late VocabRepository repository;

  setUp(() async => repository = await create());

  group('getAll', () {
    test('returns an empty list for a fresh repository', () async {
      expect(await repository.getAll(), isEmpty);
    });

    test('returns entries newest first, regardless of insertion order', () async {
      await repository.save(contractVocab('old', createdAt: DateTime.utc(2026, 1, 1)));
      await repository.save(contractVocab('new', createdAt: DateTime.utc(2026, 3, 1)));
      await repository.save(contractVocab('mid', createdAt: DateTime.utc(2026, 2, 1)));

      final ids = (await repository.getAll()).map((v) => v.id).toList();

      expect(ids, ['new', 'mid', 'old']);
    });

    test('returns a copy, so mutating the result cannot corrupt the store', () async {
      await repository.save(contractVocab('a'));

      (await repository.getAll()).clear();

      expect(await repository.getAll(), hasLength(1));
    });

    test('preserves every field through a save and read cycle', () async {
      final full = contractVocab('a').copyWith(
        lastShownAt: DateTime.utc(2026, 4, 5, 7, 30),
        timesShown: 4,
      );
      await repository.save(full);

      expect((await repository.getAll()).single, equals(full));
    });

    test('preserves a null lastShownAt', () async {
      await repository.save(contractVocab('a'));

      expect((await repository.getAll()).single.lastShownAt, isNull);
    });
  });

  group('save', () {
    test('adds an entry that was not stored before', () async {
      await repository.save(contractVocab('a'));

      expect(await repository.getById('a'), equals(contractVocab('a')));
    });

    test('replaces the existing entry when the id is already stored', () async {
      await repository.save(contractVocab('a'));
      await repository.save(contractVocab('a').copyWith(translation: 'corrected'));

      final stored = await repository.getAll();

      expect(stored, hasLength(1));
      expect(stored.single.translation, 'corrected');
    });
  });

  group('getById', () {
    test('returns null when no entry carries that id', () async {
      expect(await repository.getById('missing'), isNull);
    });
  });

  group('delete', () {
    test('removes the entry with the given id', () async {
      await repository.save(contractVocab('a'));
      await repository.delete('a');

      expect(await repository.getAll(), isEmpty);
    });

    test('leaves other entries untouched', () async {
      await repository.save(contractVocab('a'));
      await repository.save(contractVocab('b'));

      await repository.delete('a');

      expect((await repository.getAll()).single.id, 'b');
    });

    test('is a no-op for an unknown id rather than throwing', () async {
      await expectLater(repository.delete('missing'), completes);
    });
  });
}
