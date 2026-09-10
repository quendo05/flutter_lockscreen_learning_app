import 'package:flutter/material.dart';

import '../view_models/vocab_list_view_model.dart';
import 'add_vocab_sheet.dart';
import 'vocab_list_tile.dart';

/// Lists the user's saved vocabulary and lets them add or remove entries.
class VocabListScreen extends StatefulWidget {
  const VocabListScreen({required this.viewModel, super.key});

  final VocabListViewModel viewModel;

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
      appBar: AppBar(title: const Text('Vocabulary')),
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
      return _MessageState(
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
      return const _MessageState(
        icon: Icons.menu_book_outlined,
        title: 'No vocabulary yet',
        message: 'Add your first term and it will start appearing on your '
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

/// Shared layout for the empty and error states.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
