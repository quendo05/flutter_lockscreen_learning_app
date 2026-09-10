import 'package:flutter/material.dart';

import '../../../data/repositories/deck_repository.dart';
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
    super.key,
  });

  final Deck deck;
  final VocabRepository vocabRepository;
  final DeckRepository deckRepository;

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

  /// Opens the deck's settings, then adopts whatever came back so the title
  /// and the language pair for new terms both reflect the edit.
  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<Deck>(
      MaterialPageRoute<Deck>(
        builder: (_) => DeckSettingsScreen(
          viewModel: DeckSettingsViewModel(
            deck: _deck,
            repository: widget.deckRepository,
          ),
        ),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() => _deck = updated);
    _viewModel.adoptDeck(updated);
  }

  @override
  Widget build(BuildContext context) {
    return VocabListScreen(
      title: _deck.name,
      viewModel: _viewModel,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Deck settings',
          onPressed: _openSettings,
        ),
      ],
    );
  }
}
