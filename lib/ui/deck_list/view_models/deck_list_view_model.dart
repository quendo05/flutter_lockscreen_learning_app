import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';
import '../../../utils/clock.dart';
import '../../../utils/id_generator.dart';
import '../../core/view_models/loadable_view_model.dart';

/// Drives the decks screen: which decks exist, how full they are, and which
/// one is currently feeding the lock screen.
class DeckListViewModel extends LoadableViewModel {
  DeckListViewModel({
    required this._deckRepository,
    required this._vocabRepository,
    required this._settingsRepository,
    Clock? clock,
    IdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? generateId;

  final DeckRepository _deckRepository;
  final VocabRepository _vocabRepository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;
  final IdGenerator _idGenerator;

  List<Deck> _decks = const [];
  Map<String, int> _termCounts = const {};
  String? _activeDeckId;

  /// All decks, oldest first.
  List<Deck> get decks => _decks;

  /// The deck currently feeding the lock screen.
  String? get activeDeckId => _activeDeckId;

  /// How many terms [deckId] holds.
  int termCountFor(String deckId) => _termCounts[deckId] ?? 0;

  @override
  bool get hasNoContent => _decks.isEmpty;

  @override
  String get loadErrorMessage => 'Could not read your decks. Please try again.';

  /// Creates a deck from the name the user typed.
  Future<void> createDeck(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      rejectInput('Give the deck a name.');
      return;
    }

    await guard(
      () => _deckRepository.save(
        Deck(id: _idGenerator(), name: trimmed, createdAt: _clock()),
      ),
    );
  }

  /// Points the lock screen at [deckId].
  Future<void> setActiveDeck(String deckId) =>
      guard(() => _settingsRepository.setActiveDeckId(deckId));

  @override
  Future<void> readContent() async {
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
  }

  @override
  void discardContent() {
    _decks = const [];
    _termCounts = const {};
  }
}
