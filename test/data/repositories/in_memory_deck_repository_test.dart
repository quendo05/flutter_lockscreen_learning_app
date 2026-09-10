import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_deck_repository.dart';

import 'deck_repository_contract.dart';

void main() {
  group('InMemoryDeckRepository', () {
    runDeckRepositoryContract(() async => InMemoryDeckRepository());
  });

  test('accepts decks supplied at construction', () async {
    final repository = InMemoryDeckRepository(
      initialDecks: [contractDeck('seeded')],
    );

    expect((await repository.getAll()).single.id, 'seeded');
  });
}
