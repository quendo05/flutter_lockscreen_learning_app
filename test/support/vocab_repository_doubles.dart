import 'dart:async';

import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';

/// A repository whose every call fails, for exercising error paths.
///
/// Shared rather than redeclared per test file: these have to be updated
/// whenever [VocabRepository] gains a method, and four copies made that a
/// chore instead of a one-line change.
class FailingVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getByDeck(String deckId) async =>
      throw Exception('offline');
  @override
  Future<Vocab?> getById(String id) async => throw Exception('offline');
  @override
  Future<void> save(Vocab vocab) async => throw Exception('offline');
  @override
  Future<void> delete(String id) async => throw Exception('offline');
}

/// A repository whose reads never complete, so a screen stays in its loading
/// state for as long as the test needs.
class HangingVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getByDeck(String deckId) =>
      Completer<List<Vocab>>().future;
  @override
  Future<Vocab?> getById(String id) async => null;
  @override
  Future<void> save(Vocab vocab) async {}
  @override
  Future<void> delete(String id) async {}
}
