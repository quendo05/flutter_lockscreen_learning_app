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

  /// Deletes the entry with [id].
  Future<void> deleteVocab(String id) => guard(() => _repository.delete(id));

  @override
  Future<void> readContent() async {
    _vocabs = await _repository.getByDeck(deck.id);
  }

  @override
  void discardContent() {
    _vocabs = const [];
  }
}
