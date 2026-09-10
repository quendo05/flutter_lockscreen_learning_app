import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/scheduled_vocab.dart';
import '../../../domain/use_cases/build_vocab_schedule_use_case.dart';
import '../../../utils/clock.dart';
import '../../core/view_models/loadable_view_model.dart';

/// Drives the home screen: what the lock screen will show next, and how much
/// vocabulary is behind it.
class HomeViewModel extends LoadableViewModel {
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

  int _vocabularyCount = 0;
  List<ScheduledVocab> _upcoming = const [];
  Duration _displayInterval = Duration.zero;
  String? _activeDeckName;

  /// How many terms the user has saved in the deck feeding the lock screen.
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

  @override
  bool get hasNoContent => _vocabularyCount == 0;

  @override
  String get loadErrorMessage =>
      'Could not read your vocabulary. Please try again.';

  @override
  Future<void> readContent() async {
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
  }

  @override
  void discardContent() {
    _upcoming = const [];
    _vocabularyCount = 0;
  }
}
