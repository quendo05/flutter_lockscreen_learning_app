import 'package:flutter/foundation.dart';

import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';

/// Supplies the current time. Injectable so tests stay deterministic.
typedef Clock = DateTime Function();

/// Supplies ids for newly created decks.
typedef IdGenerator = String Function();

/// Drives the decks screen: which decks exist, how full they are, and which
/// one is currently feeding the lock screen.
class DeckListViewModel extends ChangeNotifier {
  DeckListViewModel({
    required this._deckRepository,
    required this._vocabRepository,
    required this._settingsRepository,
    Clock? clock,
    IdGenerator? idGenerator,
  })  : _clock = clock ?? DateTime.now,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final DeckRepository _deckRepository;
  final VocabRepository _vocabRepository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;
  final IdGenerator _idGenerator;

  List<Deck> _decks = const [];
  Map<String, int> _termCounts = const {};
  String? _activeDeckId;
  bool _isLoading = false;
  String? _loadError;
  String? _validationMessage;

  /// All decks, oldest first.
  List<Deck> get decks => _decks;

  /// True while the repositories are being read.
  bool get isLoading => _isLoading;

  /// Set when the store could not be read; replaces the list.
  String? get loadError => _loadError;

  /// Set when the user's input was unusable. Kept apart from [loadError] so a
  /// blank name never wipes the list of decks off the screen.
  String? get validationMessage => _validationMessage;

  /// The deck currently feeding the lock screen.
  String? get activeDeckId => _activeDeckId;

  /// True only when loading succeeded and no decks exist.
  bool get hasNoDecks =>
      !_isLoading && _loadError == null && _decks.isEmpty;

  /// How many terms [deckId] holds.
  int termCountFor(String deckId) => _termCounts[deckId] ?? 0;

  /// Marks the validation message as delivered.
  void clearValidationMessage() => _validationMessage = null;

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    await _refresh();
  }

  /// Creates a deck from the name the user typed.
  Future<void> createDeck(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _validationMessage = 'Give the deck a name.';
      notifyListeners();
      return;
    }

    await _guard(
      () => _deckRepository.save(
        Deck(id: _idGenerator(), name: trimmed, createdAt: _clock()),
      ),
    );
  }

  /// Points the lock screen at [deckId].
  Future<void> setActiveDeck(String deckId) async {
    await _guard(() => _settingsRepository.setActiveDeckId(deckId));
  }

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
      final decks = await _deckRepository.getAll();
      final activeDeckId = await _settingsRepository.getActiveDeckId();

      // One query per deck. Fine at this scale, and it keeps the repository
      // contract small; revisit if someone keeps hundreds of decks.
      final counts = <String, int>{};
      for (final deck in decks) {
        counts[deck.id] = (await _vocabRepository.getByDeck(deck.id)).length;
      }

      _decks = decks;
      _activeDeckId = activeDeckId;
      _termCounts = counts;
      _loadError = null;
    } on Object catch (error) {
      _reportFailure(error);
      return;
    }

    _isLoading = false;
    notifyListeners();
  }

  void _reportFailure(Object error) {
    debugPrint('DeckListViewModel: $error');
    _decks = const [];
    _termCounts = const {};
    _isLoading = false;
    _loadError = 'Could not read your decks. Please try again.';
    notifyListeners();
  }

  static String _defaultIdGenerator() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
