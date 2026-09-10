import 'package:flutter/material.dart';

import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';
import '../view_models/vocab_list_view_model.dart';
import 'vocab_list_screen.dart';

/// One deck's vocabulary, as a pushed page.
///
/// Owns the view model's lifetime, since a new one is needed per deck and it
/// must be disposed when the page is popped.
class DeckVocabPage extends StatefulWidget {
  const DeckVocabPage({
    required this.deck,
    required this.vocabRepository,
    super.key,
  });

  final Deck deck;
  final VocabRepository vocabRepository;

  @override
  State<DeckVocabPage> createState() => _DeckVocabPageState();
}

class _DeckVocabPageState extends State<DeckVocabPage> {
  late final VocabListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VocabListViewModel(
      deckId: widget.deck.id,
      repository: widget.vocabRepository,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VocabListScreen(title: widget.deck.name, viewModel: _viewModel);
  }
}
