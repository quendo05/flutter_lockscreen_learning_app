import 'package:flutter/foundation.dart';

import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/scheduled_vocab.dart';
import '../../../domain/use_cases/build_vocab_schedule_use_case.dart';

/// Supplies the current time. Injectable so tests stay deterministic.
typedef Clock = DateTime Function();

/// Drives the home screen: what the lock screen will show next, and how much
/// vocabulary is behind it.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._vocabRepository,
    required this._deckRepository,
    required this._settingsRepository,
    this._buildSchedule = const BuildVocabScheduleUseCase(),
    Clock? clock,
  }) : _clock = clock ?? DateTime.now;

  final VocabRepository _vocabRepository;
  final DeckRepository _deckRepository;
  final SettingsRepository _settingsRepository;
  final BuildVocabScheduleUseCase _buildSchedule;
  final Clock _clock;

  bool _isLoading = false;
  String? _loadError;
  int _vocabularyCount = 0;
  List<ScheduledVocab> _upcoming = const [];
  Duration _displayInterval = Duration.zero;
  String? _activeDeckName;

  /// True while the repositories are being read.
  bool get isLoading => _isLoading;

  /// Set when the store could not be read.
  String? get loadError => _loadError;

  /// How many terms the user has saved.
  int get vocabularyCount => _vocabularyCount;

  /// The term due now, or null when there is nothing to show.
  ScheduledVocab? get nextUp => _upcoming.isEmpty ? null : _upcoming.first;

  /// When the term after [nextUp] takes over, or null if there is none.
  DateTime? get followingAt =>
      _upcoming.length < 2 ? null : _upcoming[1].showAt;

  /// The configured gap between two lock screen terms.
  Duration get displayInterval => _displayInterval;

  /// The name of the deck currently feeding the lock screen.
  String? get activeDeckName => _activeDeckName;

  /// True only when loading succeeded and the user has saved nothing yet.
  /// A failed read is not an empty collection, so it must not claim to be one.
  bool get hasNoVocabulary =>
      !_isLoading && _loadError == null && _vocabularyCount == 0;

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      // Only the active deck reaches the lock screen, so only it belongs here.
      final activeDeckId = await _settingsRepository.getActiveDeckId();
      final vocabs = await _vocabRepository.getByDeck(activeDeckId);
      _activeDeckName = (await _deckRepository.getById(activeDeckId))?.name;
      _displayInterval = await _settingsRepository.getDisplayInterval();
      _vocabularyCount = vocabs.length;

      // Two entries is enough for the screen: the term showing now, and the
      // time the next one takes over.
      _upcoming = _buildSchedule(
        vocabs: vocabs,
        interval: _displayInterval,
        from: _clock(),
        count: vocabs.isEmpty ? 0 : 2,
      );
    } on Object catch (error) {
      debugPrint('HomeViewModel: $error');
      _upcoming = const [];
      _vocabularyCount = 0;
      _isLoading = false;
      _loadError = 'Could not read your vocabulary. Please try again.';
      notifyListeners();
      return;
    }

    _isLoading = false;
    notifyListeners();
  }
}
