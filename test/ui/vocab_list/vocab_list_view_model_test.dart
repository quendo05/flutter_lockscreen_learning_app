import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/repositories/in_memory_vocab_repository.dart';
import 'package:lockscreen_learning_app/data/repositories/vocab_repository.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/view_models/vocab_list_view_model.dart';

import '../../support/vocab_repository_doubles.dart';

void main() {
  final testDeck = Deck(
    id: 'd1',
    name: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    displayInterval: const Duration(hours: 3),
    createdAt: DateTime.utc(2026, 1, 1),
  );

  final fixedNow = DateTime.utc(2026, 6, 1, 12);

  VocabListViewModel buildViewModel(VocabRepository repository) {
    var counter = 0;
    return VocabListViewModel(
      deck: testDeck,
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
      final viewModel = buildViewModel(FailingVocabRepository());

      await viewModel.load();

      expect(viewModel.loadError, isNotNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('clears a previous error after a successful reload', () async {
      final viewModel = buildViewModel(FailingVocabRepository());
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

  group('deck scoping', () {
    test('shows only the terms belonging to this deck', () async {
      final repository = InMemoryVocabRepository();
      final other = VocabListViewModel(
        deck: testDeck.copyWith(id: 'other-deck'),
        repository: repository,
      );
      await other.addVocab(term: 'le livre', translation: 'das Buch');

      final viewModel = buildViewModel(repository);
      await viewModel.addVocab(term: 'el libro', translation: 'das Buch');

      expect(viewModel.vocabs.single.term, 'el libro');
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

      await viewModel.addVocab(
        term: '  la casa  ',
        translation: '  das Haus  ',
      );

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

    test('leaves already-saved entries alone when input is rejected', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());
      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');

      await viewModel.addVocab(term: '  ', translation: 'das Buch');

      expect(viewModel.vocabs.single.term, 'la casa');
      expect(viewModel.loadError, isNull);
      expect(viewModel.validationMessage, isNotNull);
    });

    test('refuses a blank translation', () async {
      final viewModel = buildViewModel(InMemoryVocabRepository());

      await viewModel.addVocab(term: 'la casa', translation: '  ');

      expect(viewModel.vocabs, isEmpty);
      expect(viewModel.validationMessage, isNotNull);
    });
  });

  Future<VocabListViewModel> withTwoTerms() async {
    final viewModel = buildViewModel(InMemoryVocabRepository());
    await viewModel.addVocab(term: 'la casa', translation: 'das Haus');
    await viewModel.addVocab(term: 'el perro', translation: 'der Hund');
    return viewModel;
  }

  group('selection', () {
    test('starts switched off, so the list opens ready to read', () async {
      final viewModel = await withTwoTerms();

      expect(viewModel.isSelecting, isFalse);
      expect(viewModel.selectedCount, 0);
    });

    test('marks the entry that began it, so a long press takes one step', () async {
      final viewModel = await withTwoTerms();

      viewModel.beginSelection('id-1');

      expect(viewModel.isSelecting, isTrue);
      expect(viewModel.isSelected('id-1'), isTrue);
      expect(viewModel.selectedCount, 1);
    });

    test('enters with nothing marked when no entry began it', () async {
      final viewModel = await withTwoTerms();

      viewModel.beginSelection();

      expect(viewModel.isSelecting, isTrue);
      expect(viewModel.selectedCount, 0);
    });

    test('toggles a mark off again on a second tap', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection('id-1');

      viewModel.toggleSelection('id-1');

      expect(viewModel.isSelected('id-1'), isFalse);
    });

    test('marks everything, then clears everything, from one action', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection();

      viewModel.toggleSelectAll();
      expect(viewModel.areAllSelected, isTrue);
      expect(viewModel.selectedCount, 2);

      viewModel.toggleSelectAll();
      expect(viewModel.areAllSelected, isFalse);
      expect(viewModel.selectedCount, 0);
    });

    test('offers a single selection only when exactly one is marked', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection('id-1');

      expect(viewModel.singleSelection?.term, 'la casa');

      viewModel.toggleSelection('id-2');
      expect(viewModel.singleSelection, isNull);
    });

    test('leaving selection drops every mark, so it cannot come back armed', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection('id-1');

      viewModel.endSelection();

      expect(viewModel.isSelecting, isFalse);
      expect(viewModel.selectedCount, 0);
    });

    test('forgets a mark on an entry that is no longer there', () async {
      final repository = InMemoryVocabRepository();
      final viewModel = buildViewModel(repository);
      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');
      viewModel.beginSelection('id-1');

      await repository.delete('id-1');
      await viewModel.load();

      expect(viewModel.selectedCount, 0);
    });
  });

  group('deleteSelected', () {
    test('removes every marked entry and keeps the rest', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection('id-1');

      await viewModel.deleteSelected();

      expect(viewModel.vocabs.single.term, 'el perro');
    });

    test('empties the deck when everything is marked', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection();
      viewModel.toggleSelectAll();

      await viewModel.deleteSelected();

      expect(viewModel.vocabs, isEmpty);
    });

    test('leaves selection afterwards, because there is nothing left to act on', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection('id-1');

      await viewModel.deleteSelected();

      expect(viewModel.isSelecting, isFalse);
      expect(viewModel.selectedCount, 0);
    });

    test('does nothing when no entry is marked', () async {
      final viewModel = await withTwoTerms();
      viewModel.beginSelection();

      await viewModel.deleteSelected();

      expect(viewModel.vocabs, hasLength(2));
    });
  });

  group('editVocab', () {
    test('rewrites the entry in place, so the list shows the new wording', () async {
      final viewModel = await withTwoTerms();
      final original = viewModel.vocabs.firstWhere((v) => v.id == 'id-1');

      await viewModel.editVocab(
        vocab: original,
        term: 'la casita',
        translation: 'das Häuschen',
      );

      final edited = viewModel.vocabs.firstWhere((v) => v.id == 'id-1');
      expect(edited.term, 'la casita');
      expect(edited.translation, 'das Häuschen');
      expect(viewModel.vocabs, hasLength(2));
    });

    test('keeps the practice counts, so a correction does not reset progress', () async {
      final repository = InMemoryVocabRepository();
      final viewModel = buildViewModel(repository);
      await viewModel.addVocab(term: 'la casa', translation: 'das Haus');
      final shown = viewModel.vocabs.single.markShown(fixedNow);
      await repository.save(shown);
      await viewModel.load();

      await viewModel.editVocab(
        vocab: viewModel.vocabs.single,
        term: 'la casita',
        translation: 'das Häuschen',
      );

      expect(viewModel.vocabs.single.timesShown, 1);
      expect(viewModel.vocabs.single.lastShownAt, fixedNow);
    });

    test('trims surrounding whitespace from what the user typed', () async {
      final viewModel = await withTwoTerms();

      await viewModel.editVocab(
        vocab: viewModel.vocabs.firstWhere((v) => v.id == 'id-1'),
        term: '  la casita  ',
        translation: '  das Häuschen  ',
      );

      final edited = viewModel.vocabs.firstWhere((v) => v.id == 'id-1');
      expect(edited.term, 'la casita');
    });

    test('refuses a blank term instead of storing an unusable entry', () async {
      final viewModel = await withTwoTerms();
      final original = viewModel.vocabs.firstWhere((v) => v.id == 'id-1');

      await viewModel.editVocab(
        vocab: original,
        term: '   ',
        translation: 'das Haus',
      );

      expect(viewModel.validationMessage, isNotNull);
      expect(
        viewModel.vocabs.firstWhere((v) => v.id == 'id-1').term,
        'la casa',
      );
    });
  });
}
