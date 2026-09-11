import 'package:flutter/foundation.dart';

import '../../../config/defaults.dart';
import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../data/services/schedule_store.dart';
import '../../../domain/models/deck.dart';
import '../../../domain/models/published_schedule.dart';
import '../../../domain/models/scheduled_vocab.dart';
import '../../../domain/models/vocab.dart';
import '../../../domain/use_cases/build_vocab_schedule_use_case.dart';
import '../../../domain/use_cases/record_shown_terms_use_case.dart';
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
    this._recordShown = const RecordShownTermsUseCase(),
    this._scheduleStore,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now;

  final VocabRepository _vocabRepository;
  final DeckRepository _deckRepository;
  final SettingsRepository _settingsRepository;
  final BuildVocabScheduleUseCase _buildSchedule;
  final RecordShownTermsUseCase _recordShown;

  /// Where the queue is left for the lock screen. Null where there is no
  /// native side to read it, which is the web build and most tests.
  final ScheduleStore? _scheduleStore;
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
    final activeDeck = await _deckRepository.getById(activeDeckId);

    final previous = await _lastPublished();

    // Before anything is worked out: the terms on screen should reflect the
    // turns they have already had, not the state they were left in.
    final vocabs = await _recordWhatWasShown(
      await _vocabRepository.getByDeck(activeDeckId),
      previous,
    );
    _activeDeckName = activeDeck?.name;
    // The pace belongs to the deck, so a patient deck and a brisk one can
    // coexist instead of sharing one global setting.
    _displayInterval = activeDeck?.displayInterval ?? defaultDisplayInterval;
    _vocabularyCount = vocabs.length;

    // One queue serves both readers: this screen shows the first two, the
    // lock screen works through all of them.
    _upcoming = _buildSchedule(
      vocabs: vocabs,
      interval: _displayInterval,
      from: _continueFrom(previous, activeDeck),
      count: vocabs.isEmpty ? 0 : publishedScheduleLength,
    );

    await _publish(activeDeck);
  }

  /// The queue published last, or null if there is none to be had.
  ///
  /// A store that cannot be read is treated as an empty one: the app would
  /// otherwise refuse to start over a file it is about to replace anyway.
  Future<PublishedSchedule?> _lastPublished() async {
    final store = _scheduleStore;
    if (store == null) return null;

    try {
      return await store.read();
    } on Object catch (error) {
      debugPrint('HomeViewModel: could not read the published queue: $error');
      return null;
    }
  }

  /// Where the rebuilt queue begins.
  ///
  /// Not simply now. Rebuilding from the present moment would restart the slot
  /// already running every single time the app is opened, so a term would
  /// never get its full turn and the rotation would jump forward on every
  /// visit. Picking up at the start of the running slot instead leaves what is
  /// showing showing, and keeps every later boundary where it already was.
  ///
  /// Starts afresh only when there is genuinely nothing to carry on from: no
  /// previous queue, another deck, a changed pace, or a queue that ran out
  /// while the app was away. Those are all changes the user made or waited
  /// for, and each should take effect at once.
  DateTime _continueFrom(PublishedSchedule? previous, Deck? deck) {
    final now = _clock();
    if (previous == null || deck == null) return now;
    if (previous.deckId != deck.id) return now;
    if (previous.interval != deck.displayInterval) return now;

    return previous.currentAt(now)?.showAt ?? now;
  }

  /// Brings the practice counts up to date with the queue the lock screen
  /// has been working through, and returns the terms as they now stand.
  ///
  /// A failure is logged and the terms are handed back untouched. The counts
  /// only influence what comes up next, so losing one round of them is a far
  /// smaller thing than refusing to show the screen over it.
  Future<List<Vocab>> _recordWhatWasShown(
    List<Vocab> vocabs,
    PublishedSchedule? previous,
  ) async {
    try {
      final shown = _recordShown(
        published: previous,
        vocabs: vocabs,
        now: _clock(),
      );
      if (shown.isEmpty) return vocabs;

      for (final vocab in shown) {
        await _vocabRepository.save(vocab);
      }

      // Swapped in rather than re-read: the store was just told about these,
      // so another query would only ask it to repeat itself.
      final marked = {for (final vocab in shown) vocab.id: vocab};
      return [for (final vocab in vocabs) marked[vocab.id] ?? vocab];
    } on Object catch (error) {
      debugPrint('HomeViewModel: could not record what was shown: $error');
      return vocabs;
    }
  }

  /// Leaves the queue where the lock screen will find it.
  ///
  /// Published even when it is empty, so emptying a deck takes its terms off
  /// the lock screen instead of leaving the last queue running.
  ///
  /// A failure here is logged and swallowed: the vocabulary was read fine, the
  /// screen has everything it needs, and a stale lock screen is not something
  /// the user could act on from here. It does mean a device that cannot write
  /// goes quietly stale.
  Future<void> _publish(Deck? deck) async {
    final store = _scheduleStore;
    if (store == null || deck == null) return;

    try {
      await store.write(
        PublishedSchedule.of(
          generatedAt: _clock(),
          deck: deck,
          upcoming: _upcoming,
        ),
      );
    } on Object catch (error) {
      debugPrint('HomeViewModel: could not publish the schedule: $error');
    }
  }

  @override
  void discardContent() {
    _upcoming = const [];
    _vocabularyCount = 0;
  }
}
