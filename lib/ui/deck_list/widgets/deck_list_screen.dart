import 'package:flutter/material.dart';

import '../../../domain/models/deck.dart';
import '../../core/widgets/message_state.dart';
import '../view_models/deck_list_view_model.dart';
import 'create_deck_sheet.dart';
import 'deck_list_tile.dart';

/// Lists the user's decks and lets them create one or choose which feeds the
/// lock screen.
class DeckListScreen extends StatefulWidget {
  const DeckListScreen({
    required this.viewModel,
    required this.onOpenDeck,
    super.key,
  });

  final DeckListViewModel viewModel;

  /// Opens a deck's vocabulary. Navigation belongs to the caller.
  final ValueChanged<Deck> onOpenDeck;

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_surfaceValidationMessage);
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_surfaceValidationMessage);
    super.dispose();
  }

  /// Shows input problems transiently, leaving the deck list in place.
  void _surfaceValidationMessage() {
    final message = widget.viewModel.validationMessage;
    if (message == null || !mounted) return;

    widget.viewModel.clearValidationMessage();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateDeckSheet(onSubmit: widget.viewModel.createDeck),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decks')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) => _DeckListBody(
          viewModel: widget.viewModel,
          onOpenDeck: widget.onOpenDeck,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        tooltip: 'Create deck',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DeckListBody extends StatelessWidget {
  const _DeckListBody({required this.viewModel, required this.onOpenDeck});

  final DeckListViewModel viewModel;
  final ValueChanged<Deck> onOpenDeck;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = viewModel.loadError;
    if (error != null) {
      return MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Something went wrong',
        message: error,
        action: FilledButton.tonal(
          onPressed: viewModel.load,
          child: const Text('Try again'),
        ),
      );
    }

    if (viewModel.isEmpty) {
      return const MessageState(
        icon: Icons.style_outlined,
        title: 'No decks yet',
        message: 'Create a deck to group the terms you want to learn together.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: viewModel.decks.length,
      itemBuilder: (context, index) {
        final deck = viewModel.decks[index];
        return DeckListTile(
          deck: deck,
          termCount: viewModel.termCountFor(deck.id),
          isActive: deck.id == viewModel.activeDeckId,
          onOpen: () => onOpenDeck(deck),
          onActivate: () => viewModel.setActiveDeck(deck.id),
        );
      },
    );
  }
}
