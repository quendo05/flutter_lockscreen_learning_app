import 'package:flutter/material.dart';

import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';
import '../../deck_settings/view_models/deck_settings_view_model.dart';
import '../../deck_settings/widgets/deck_settings_screen.dart';
import '../view_models/vocab_list_view_model.dart';
import 'vocab_list_screen.dart';

/// One deck's vocabulary, as a pushed page.
///
/// Owns the view model's lifetime, since a new one is needed per deck and it
/// must be disposed when the page is popped. Also owns the deck itself, which
/// its own settings screen can change while the page is open.
class DeckVocabPage extends StatefulWidget {
  const DeckVocabPage({
    required this.deck,
    required this.vocabRepository,
    required this.deckRepository,
    required this.settingsRepository,
    super.key,
  });

  final Deck deck;
  final VocabRepository vocabRepository;
  final DeckRepository deckRepository;

  /// Needed only so the settings screen can hand the lock screen to another
  /// deck when this one is deleted.
  final SettingsRepository settingsRepository;

  @override
  State<DeckVocabPage> createState() => _DeckVocabPageState();
}

class _DeckVocabPageState extends State<DeckVocabPage> {
  late final VocabListViewModel _viewModel;
  late Deck _deck;

  @override
  void initState() {
    super.initState();
    _deck = widget.deck;
    _viewModel = VocabListViewModel(
      deck: _deck,
      repository: widget.vocabRepository,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Opens the deck's settings and acts on what comes back: an edit is
  /// adopted so the title and the pair for new terms reflect it, and a
  /// deletion closes this page, which has nothing left to show.
  Future<void> _openSettings() async {
    final outcome = await Navigator.of(context).push<DeckSettingsOutcome>(
      MaterialPageRoute<DeckSettingsOutcome>(
        builder: (_) => DeckSettingsScreen(
          viewModel: DeckSettingsViewModel(
            deck: _deck,
            deckRepository: widget.deckRepository,
            vocabRepository: widget.vocabRepository,
            settingsRepository: widget.settingsRepository,
          ),
        ),
      ),
    );

    if (!mounted) return;

    switch (outcome) {
      case DeckSaved(:final deck):
        setState(() => _deck = deck);
        _viewModel.adoptDeck(deck);
      case DeckDeleted():
        Navigator.of(context).pop();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VocabListScreen(
      title: _deck.name,
      viewModel: _viewModel,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Deck settings',
          onPressed: _openSettings,
        ),
      ],
    );
  }
}
