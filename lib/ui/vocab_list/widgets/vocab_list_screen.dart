import 'package:flutter/material.dart';

import '../../core/widgets/message_state.dart';
import '../view_models/vocab_list_view_model.dart';
import 'add_vocab_sheet.dart';
import 'vocab_list_tile.dart';

/// Lists the user's saved vocabulary and lets them add or remove entries.
class VocabListScreen extends StatefulWidget {
  const VocabListScreen({
    required this.title,
    required this.viewModel,
    this.actions = const [],
    super.key,
  });

  /// Shown in the app bar — the name of the deck being browsed.
  final String title;

  final VocabListViewModel viewModel;

  /// Extra app bar actions, supplied by whoever opened this screen.
  final List<Widget> actions;

  @override
  State<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends State<VocabListScreen> {
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

  /// Shows input problems as a transient message, leaving the list in place.
  void _surfaceValidationMessage() {
    final message = widget.viewModel.validationMessage;
    if (message == null || !mounted) return;

    widget.viewModel.clearValidationMessage();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddVocabSheet(
        onSubmit: (term, translation) =>
            widget.viewModel.addVocab(term: term, translation: translation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: widget.actions),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) => _VocabListBody(viewModel: widget.viewModel),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        tooltip: 'Add vocabulary',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Picks the right state to render: loading, error, empty, or the list itself.
class _VocabListBody extends StatelessWidget {
  const _VocabListBody({required this.viewModel});

  final VocabListViewModel viewModel;

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
        icon: Icons.menu_book_outlined,
        title: 'No vocabulary yet',
        message:
            'Add your first term and it will start appearing on your '
            'lock screen.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: viewModel.vocabs.length,
      itemBuilder: (context, index) {
        final vocab = viewModel.vocabs[index];
        return VocabListTile(
          vocab: vocab,
          onDelete: () => viewModel.deleteVocab(vocab.id),
        );
      },
    );
  }
}
