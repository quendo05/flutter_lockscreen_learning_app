import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/view_models/vocab_list_view_model.dart';

/// A repository whose every call fails, for exercising the error path.
class _FailingVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getAll() async => throw Exception('database unavailable');

  @override
  Future<Vocab?> getById(String id) async => throw Exception('database unavailable');

  @override
  Future<void> save(Vocab vocab) async => throw Exception('database unavailable');

  @override
  Future<void> delete(String id) async => throw Exception('database unavailable');
}

void main() {
  final fixedNow = DateTime.utc(2026, 6, 1, 12);

  VocabListViewModel buildViewModel(VocabRepository repository) {
    var counter = 0;
    return VocabListViewModel(
      repository: repository,
      clock: () => fixedNow,
      idGenerator: () => 'id-${++counter}',
    );
  }

  group('load', () {
    test('reports no entries and no error for an empty repository', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.load();

      expect(viewModel.vocabs, isEmpty);
      expect(viewModel.loadError, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('exposes the stored entries once loading finishes', () async {
      final repository = InMemoryVocabRepository();
      final viewModel = buildViewModel(repository);
      await viewModel.addVocab(term: 'el perro', translation: 'der Hund');

      await viewModel.load();

      expect(viewModel.vocabs.single.term, 'el perro');
    });

    test('sets isLoading while the repository call is still in flight', () {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      final pending = viewModel.load();

      expect(viewModel.isLoading, isTrue);
      return pending;
    });

    test('surfaces a readable message when the repository fails', () async {
      final viewModel = buildViewModel(_FailingVocabRepository());

      await viewModel.load();

      expect(viewModel.loadError, isNotNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('clears a previous error after a successful reload', () async {
      final viewModel = buildViewModel(_FailingVocabRepository());
      await viewModel.load();

      final recovered = buildViewModel(InMemoryVocabRepository());
      await recovered.load();

      expect(recovered.loadError, isNull);
    });

    test('notifies listeners so the screen rebuilds', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(notifications, greaterThan(0));
    });
  });

  group('addVocab', () {
    test('stores the new entry and shows it in the list', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');

      expect(viewModel.vocabs.single.term, 'la casa');
      expect(viewModel.vocabs.single.translation, 'das Haus');
    });

    test('stamps the entry with the current time and a generated id', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');

      expect(viewModel.vocabs.single.id, 'id-1');
      expect(viewModel.vocabs.single.createdAt, fixedNow);
    });

    test('trims surrounding whitespace from what the user typed', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.addVocab(term: '  la casa  ', translation: '  das Haus  ');

      expect(viewModel.vocabs.single.term, 'la casa');
      expect(viewModel.vocabs.single.translation, 'das Haus');
    });

    test('refuses a blank term instead of storing an unusable entry', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.addVocab(term: '   ', translation: 'das Haus');

      expect(viewModel.vocabs, isEmpty);
      expect(viewModel.validationMessage, isNotNull);
      expect(viewModel.loadError, isNull);
    });

    test('refuses a blank translation', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.addVocab(term: 'la casa', translation: '  ');

      expect(viewModel.vocabs, isEmpty);
      expect(viewModel.validationMessage, isNotNull);
    });
  });

  group('deleteVocab', () {
    test('removes the entry from the list', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());
      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');

      await viewModel.deleteVocab('id-1');

      expect(viewModel.vocabs, isEmpty);
    });

    test('keeps the other entries', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());
      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');
      await viewModel.addVocab(term: 'el perro', translation: 'der Hund');

      await viewModel.deleteVocab('id-1');

      expect(viewModel.vocabs.single.term, 'el perro');
    });
  });
}
