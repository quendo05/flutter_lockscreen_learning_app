import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/vocab.dart';
import '../../../utils/clock.dart';
import '../../../utils/id_generator.dart';
import '../../core/view_models/loadable_view_model.dart';

/// Drives the vocabulary list screen for a single deck.
class VocabListViewModel extends LoadableViewModel {
  VocabListViewModel({
    required this._deck,
    required this._repository,
    Clock? clock,
    IdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? generateId;

  Deck _deck;

  /// The deck whose terms are shown. New terms are added to it and inherit
  /// its language pair, so the pair is recorded once per deck rather than
  /// being guessed per term.
  Deck get deck => _deck;

  /// Adopts a deck whose settings were just edited, so terms added afterwards
  /// inherit the new language pair rather than the pair the page opened with.
  void adoptDeck(Deck deck) {
    _deck = deck;
    notifyListeners();
  }

  final VocabRepository _repository;
  final Clock _clock;
  final IdGenerator _idGenerator;

  List<Vocab> _vocabs = const [];

  /// The deck's entries, newest first. Empty until [load] has run.
  List<Vocab> get vocabs => _vocabs;

  final _selectedIds = <String>{};
  bool _isSelecting = false;

  /// Whether the list is marking entries rather than just showing them.
  ///
  /// Kept apart from "something is selected", so the user can enter the mode,
  /// look at the list and leave again without the screen deciding on their
  /// behalf that they were done.
  bool get isSelecting => _isSelecting;

  /// How many entries carry a mark. Drives the destructive actions, which stay
  /// unavailable at zero.
  int get selectedCount => _selectedIds.length;

  bool isSelected(String id) => _selectedIds.contains(id);

  /// True only when every entry is marked, so the toggle can say which of the
  /// two things it is about to do.
  bool get areAllSelected =>
      _vocabs.isNotEmpty && _selectedIds.length == _vocabs.length;

  /// The marked entry when exactly one is marked, otherwise null.
  ///
  /// Editing is a single-entry operation, so this is what decides whether the
  /// edit action is offered at all rather than the screen counting for itself.
  Vocab? get singleSelection {
    if (_selectedIds.length != 1) return null;

    final id = _selectedIds.first;
    for (final vocab in _vocabs) {
      if (vocab.id == id) return vocab;
    }

    return null;
  }

  /// Enters selection mode, optionally marking the entry that started it.
  ///
  /// The id is there for a long press, which in one gesture means both "start
  /// selecting" and "this one" — asking the user to do those separately would
  /// be a step nobody expects.
  void beginSelection([String? id]) {
    _isSelecting = true;
    if (id != null) _selectedIds.add(id);
    notifyListeners();
  }

  /// Leaves selection mode and drops every mark.
  void endSelection() {
    _isSelecting = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  /// Marks everything, or drops every mark when everything already carries one.
  ///
  /// One action rather than two, because the button that offers it can only
  /// occupy one place in the bar and the user's intent is unambiguous either
  /// way.
  void toggleSelectAll() {
    if (areAllSelected) {
      _selectedIds.clear();
    } else {
      _selectedIds.addAll(_vocabs.map((vocab) => vocab.id));
    }
    notifyListeners();
  }

  @override
  bool get hasNoContent => _vocabs.isEmpty;

  @override
  String get loadErrorMessage =>
      'Could not reach your saved vocabulary. Please try again.';

  /// Creates an entry from what the user typed.
  ///
  /// Blank input is rejected rather than stored, because an entry with no term
  /// could never be shown on the lock screen.
  Future<void> addVocab({
    required String term,
    required String translation,
  }) async {
    final trimmedTerm = term.trim();
    final trimmedTranslation = translation.trim();

    if (trimmedTerm.isEmpty || trimmedTranslation.isEmpty) {
      rejectInput('Enter both a term and its translation.');
      return;
    }

    await guard(
      () => _repository.save(
        Vocab(
          id: _idGenerator(),
          deckId: deck.id,
          term: trimmedTerm,
          translation: trimmedTranslation,
          sourceLanguage: deck.sourceLanguage,
          targetLanguage: deck.targetLanguage,
          createdAt: _clock(),
        ),
      ),
    );
  }

  /// Rewrites a marked entry with what the user typed.
  ///
  /// Saves over the original rather than replacing it, so the id, the deck, the
  /// language pair and the practice counts all survive the edit — a term that
  /// has been shown fifty times should not go back to the front of the queue
  /// because its spelling was corrected.
  Future<void> editVocab({
    required Vocab vocab,
    required String term,
    required String translation,
  }) async {
    final trimmedTerm = term.trim();
    final trimmedTranslation = translation.trim();

    if (trimmedTerm.isEmpty || trimmedTranslation.isEmpty) {
      rejectInput('Enter both a term and its translation.');
      return;
    }

    _clearSelection();
    await guard(
      () => _repository.save(
        vocab.copyWith(term: trimmedTerm, translation: trimmedTranslation),
      ),
    );
  }

  /// Deletes every marked entry.
  ///
  /// A loop rather than one repository call: unlike emptying a deck, a partly
  /// finished selection delete leaves the list in a state the user can see and
  /// simply repeat, which is not worth widening the repository contract for.
  ///
  /// The marks are dropped before the write, not after. Either it succeeds and
  /// they point at rows that are gone, or it fails and the list is discarded
  /// with the error — and a selection pointing at neither is worse than none.
  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final doomed = _selectedIds.toList();
    _clearSelection();

    await guard(() async {
      for (final id in doomed) {
        await _repository.delete(id);
      }
    });
  }

  void _clearSelection() {
    _isSelecting = false;
    _selectedIds.clear();
  }

  @override
  Future<void> readContent() async {
    _vocabs = await _repository.getByDeck(deck.id);
    // A mark left on a row that is no longer there would keep the count wrong
    // and the delete action armed over nothing.
    _selectedIds.retainWhere(
      (id) => _vocabs.any((vocab) => vocab.id == id),
    );
  }

  @override
  void discardContent() {
    _vocabs = const [];
    _clearSelection();
  }
}
