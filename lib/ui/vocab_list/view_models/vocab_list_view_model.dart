import 'package:flutter/foundation.dart';

import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/vocab.dart';

/// Supplies the current time. Injectable so tests stay deterministic.
typedef Clock = DateTime Function();

/// Supplies ids for newly created entries.
typedef IdGenerator = String Function();

/// Drives the vocabulary list screen.
///
/// Owns the loading, empty and error states the screen renders, so the widget
/// itself stays free of data-fetching logic.
class VocabListViewModel extends ChangeNotifier {
  VocabListViewModel({
    required this.deckId,
    required this._repository,
    Clock? clock,
    IdGenerator? idGenerator,
  })  : _clock = clock ?? DateTime.now,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  /// The deck new terms are added to.
  final String deckId;

  final VocabRepository _repository;
  final Clock _clock;
  final IdGenerator _idGenerator;

  List<Vocab> _vocabs = const [];
  bool _isLoading = false;
  String? _loadError;
  String? _validationMessage;

  /// All stored entries, newest first. Empty until [load] has run.
  List<Vocab> get vocabs => _vocabs;

  /// True while a repository call is in flight.
  bool get isLoading => _isLoading;

  /// Set when the repository could not be reached. This replaces the list,
  /// because there is nothing trustworthy to show.
  String? get loadError => _loadError;

  /// Set when the user's input was unusable. Deliberately kept separate from
  /// [loadError]: a blank field is not a failure of the app, so the saved list
  /// must stay on screen while the message is surfaced transiently.
  String? get validationMessage => _validationMessage;

  /// True when loading finished and the user has not added anything yet.
  bool get isEmpty => !_isLoading && _loadError == null && _vocabs.isEmpty;

  /// Marks the validation message as delivered.
  ///
  /// Does not notify: nothing in the tree renders from this field directly, so
  /// notifying here would only re-enter the listener that consumed it.
  void clearValidationMessage() => _validationMessage = null;

  /// Fetches every entry from the repository.
  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    await _refresh();
  }

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
      _validationMessage = 'Enter both a term and its translation.';
      notifyListeners();
      return;
    }

    final vocab = Vocab(
      id: _idGenerator(),
      deckId: deckId,
      term: trimmedTerm,
      translation: trimmedTranslation,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      createdAt: _clock(),
    );

    await _guard(() => _repository.save(vocab));
  }

  /// Deletes the entry with [id].
  Future<void> deleteVocab(String id) async {
    await _guard(() => _repository.delete(id));
  }

  /// Runs [action], then reloads the list, turning any failure into a message.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      _reportFailure(error);
      return;
    }

    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      _vocabs = await _repository.getByDeck(deckId);
      _loadError = null;
    } on Object catch (error) {
      _reportFailure(error);
      return;
    }

    _isLoading = false;
    notifyListeners();
  }

  void _reportFailure(Object error) {
    debugPrint('VocabListViewModel: $error');
    _vocabs = const [];
    _isLoading = false;
    _loadError = 'Could not reach your saved vocabulary. Please try again.';
    notifyListeners();
  }

  static String _defaultIdGenerator() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

/// The language pair, until the settings screen supplies it.
const defaultSourceLanguage = 'es';
const defaultTargetLanguage = 'de';
