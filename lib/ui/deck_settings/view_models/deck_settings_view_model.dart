import 'package:flutter/foundation.dart';

import '../../../data/repositories/deck_repository.dart';
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
  DeckSettingsViewModel({required this._deck, required this._repository});

  final DeckRepository _repository;

  Deck _deck;
  String? _validationMessage;

  /// The deck as last saved.
  Deck get deck => _deck;

  /// Set when the user's input was unusable.
  String? get validationMessage => _validationMessage;

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
      await _repository.save(updated);
    } on Object catch (error) {
      debugPrint('DeckSettingsViewModel: $error');
      return _reject('Could not save the deck. Please try again.');
    }

    _deck = updated;
    _validationMessage = null;
    notifyListeners();
    return updated;
  }

  Deck? _reject(String message) {
    _validationMessage = message;
    notifyListeners();
    return null;
  }
}
