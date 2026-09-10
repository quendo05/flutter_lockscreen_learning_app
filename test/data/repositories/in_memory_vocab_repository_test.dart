import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';

import 'vocab_repository_contract.dart';

void main() {
  group('InMemoryVocabRepository', () {
    runVocabRepositoryContract(() async => InMemoryVocabRepository());
  });

  test('accepts entries supplied at construction', () async {
    final repository = InMemoryVocabRepository(
      initialEntries: [contractVocab('seeded')],
    );

    expect((await repository.getAll()).single.id, 'seeded');
  });
}
