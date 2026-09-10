import '../../../config/defaults.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/vocab.dart';
import '../../../utils/clock.dart';
import '../../../utils/id_generator.dart';
import '../../core/view_models/loadable_view_model.dart';

/// Drives the vocabulary list screen for a single deck.
class VocabListViewModel extends LoadableViewModel {
  VocabListViewModel({
    required this.deckId,
    required this._repository,
    Clock? clock,
    IdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? generateId;

  /// The deck whose terms are shown, and that new terms are added to.
  final String deckId;

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
    String sourceLanguage = defaultSourceLanguage,
    String targetLanguage = defaultTargetLanguage,
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
          deckId: deckId,
          term: trimmedTerm,
          translation: trimmedTranslation,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          createdAt: _clock(),
        ),
      ),
    );
  }

  /// Deletes the entry with [id].
  Future<void> deleteVocab(String id) => guard(() => _repository.delete(id));

  @override
  Future<void> readContent() async {
    _vocabs = await _repository.getByDeck(deckId);
  }

  @override
  void discardContent() {
    _vocabs = const [];
  }
}
