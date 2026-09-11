import 'package:flutter/foundation.dart';

import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';

/// The narrowest and widest pace the settings screen offers, in hours.
///
/// Bounding it in the control rather than validating afterwards means the user
/// cannot express an interval that would have to be rejected.
const minDisplayIntervalHours = 1;
const maxDisplayIntervalHours = 24;

/// Drives one deck's settings: its name, the pair it is studied in, and how
/// often its terms reach the lock screen.
///
/// A plain [ChangeNotifier] rather than a LoadableViewModel: it is handed the
/// deck it edits, so it has nothing to read and no empty state to describe.
class DeckSettingsViewModel extends ChangeNotifier {
  DeckSettingsViewModel({
    required this._deck,
    required this._deckRepository,
    required this._vocabRepository,
    required this._settingsRepository,
  });

  final DeckRepository _deckRepository;
  final VocabRepository _vocabRepository;
  final SettingsRepository _settingsRepository;

  Deck _deck;
  String? _validationMessage;
  int? _termCount;
  bool _isOnlyDeck = true;

  /// The deck as last saved.
  Deck get deck => _deck;

  /// Set when the user's input was unusable, or a write failed.
  String? get validationMessage => _validationMessage;

  /// How many terms would go with this deck, or null before [load] has run.
  int? get termCount => _termCount;

  /// Whether deleting this deck is allowed at all.
  ///
  /// False until [load] says otherwise: offering a destructive action on a
  /// guess and withdrawing it a moment later is worse than showing it late.
  bool get canDelete => !_isOnlyDeck;

  /// Reads what the screen cannot work out from the deck alone: whether this
  /// is the last deck standing, and how much is inside it.
  ///
  /// A failure leaves both at their safe defaults rather than reporting an
  /// error. Nothing on the screen depends on them except the offer to delete,
  /// and withholding that offer is the right answer when we cannot tell.
  Future<void> load() async {
    try {
      final decks = await _deckRepository.getAll();
      final vocabs = await _vocabRepository.getByDeck(_deck.id);

      _isOnlyDeck = decks.length < 2;
      _termCount = vocabs.length;
    } on Object catch (error) {
      debugPrint('DeckSettingsViewModel: $error');
      return;
    }

    notifyListeners();
  }

  /// Marks the validation message as delivered.
  void clearValidationMessage() => _validationMessage = null;

  /// Stores the edited deck, returning the saved deck, or null if the input
  /// was rejected or the write failed.
  Future<Deck?> save({
    required String name,
    required String sourceLanguage,
    required String targetLanguage,
    required int intervalHours,
  }) async {
    final trimmedName = name.trim();
    final trimmedSource = sourceLanguage.trim();
    final trimmedTarget = targetLanguage.trim();

    if (trimmedName.isEmpty) {
      return _reject('Give the deck a name.');
    }
    if (trimmedSource.isEmpty || trimmedTarget.isEmpty) {
      return _reject('Name both languages.');
    }

    final updated = _deck.copyWith(
      name: trimmedName,
      sourceLanguage: trimmedSource,
      targetLanguage: trimmedTarget,
      displayInterval: Duration(hours: intervalHours),
    );

    try {
      await _deckRepository.save(updated);
    } on Object catch (error) {
      debugPrint('DeckSettingsViewModel: $error');
      return _reject('Could not save the deck. Please try again.');
    }

    _deck = updated;
    _validationMessage = null;
    notifyListeners();
    return updated;
  }

  /// Deletes the deck and everything filed under it, reporting whether it
  /// is gone.
  ///
  /// The terms go too. A term belongs to exactly one deck, so leaving them
  /// would leave rows nothing can reach and no screen can show.
  ///
  /// The last deck is refused: every install is guaranteed a deck to save
  /// into, and an install with none would have nowhere to put the next term.
  Future<bool> delete() async {
    if (_isOnlyDeck) {
      _reject('This is your only deck, so it cannot be deleted.');
      return false;
    }

    try {
      // The deck goes first on purpose. If the terms were cleared first and
      // this then failed, the user would keep a deck emptied behind their
      // back; this way a failure leaves rows nothing reads, which costs a
      // little space and nothing else.
      await _deckRepository.delete(_deck.id);
      await _vocabRepository.deleteByDeck(_deck.id);
      await _moveActiveDeckOff(_deck.id);
    } on Object catch (error) {
      debugPrint('DeckSettingsViewModel: $error');
      _reject('Could not delete the deck. Please try again.');
      return false;
    }

    return true;
  }

  /// Points the lock screen at another deck if it was drawing from this one.
  ///
  /// The oldest remaining deck, because that is the order the deck list is in
  /// and therefore the one the user already reads as first.
  Future<void> _moveActiveDeckOff(String deletedId) async {
    if (await _settingsRepository.getActiveDeckId() != deletedId) return;

    final remaining = await _deckRepository.getAll();
    if (remaining.isEmpty) return;

    await _settingsRepository.setActiveDeckId(remaining.first.id);
  }

  Deck? _reject(String message) {
    _validationMessage = message;
    notifyListeners();
    return null;
  }
}
