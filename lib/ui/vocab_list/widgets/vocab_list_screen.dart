import 'package:flutter/material.dart';

import '../../../domain/models/vocab.dart';
import '../../core/widgets/message_state.dart';
import '../view_models/vocab_list_view_model.dart';
import 'vocab_list_tile.dart';
import 'vocab_sheet.dart';

/// Lists the user's saved vocabulary and lets them add, edit or remove entries.
///
/// Removing and editing both go through selection mode rather than living on
/// the rows: a per-row delete button puts the one irreversible action on this
/// screen a stray tap away from scrolling, and gives no way to clear out ten
/// terms without ten separate confirmations.
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

  /// Extra app bar actions, supplied by whoever opened this screen. Hidden
  /// while selecting, because they act on the deck rather than on the marks.
  final List<Widget> actions;

  @override
  State<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends State<VocabListScreen> {
  VocabListViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_surfaceValidationMessage);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_surfaceValidationMessage);
    super.dispose();
  }

  /// Shows input problems as a transient message, leaving the list in place.
  void _surfaceValidationMessage() {
    final message = _viewModel.validationMessage;
    if (message == null || !mounted) return;

    _viewModel.clearValidationMessage();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSheet({Vocab? initial}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VocabSheet(
        initial: initial,
        onSubmit: (term, translation) => initial == null
            ? _viewModel.addVocab(term: term, translation: translation)
            : _viewModel.editVocab(
                vocab: initial,
                term: term,
                translation: translation,
              ),
      ),
    );
  }

  /// Asks before deleting, and names what is about to go.
  ///
  /// The same question the deck settings screen asks, for the same reason:
  /// this is the only action in the app that destroys something the user
  /// typed, and it cannot be undone.
  Future<void> _confirmDelete() async {
    final count = _viewModel.selectedCount;
    if (count == 0) return;

    final single = _viewModel.singleSelection;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(count == 1 ? 'Delete this term?' : 'Delete $count terms?'),
        content: Text(
          single != null
              ? '${single.term} will be deleted. This cannot be undone.'
              : '$count terms will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (agreed != true || !mounted) return;

    await _viewModel.deleteSelected();
  }

  List<Widget> _selectionActions() {
    final single = _viewModel.singleSelection;

    return [
      // Spelled out rather than iconised. `Icons.select_all` is a dotted
      // square that means nothing without its tooltip, and a tooltip only
      // appears on a long press — which is the one gesture this screen has
      // already given another meaning.
      //
      // Labelled with what it will do next, not with what it is, so the user
      // never has to work out which of the two states they are in.
      TextButton(
        onPressed: _viewModel.toggleSelectAll,
        child: Text(_viewModel.areAllSelected ? 'Clear' : 'Select all'),
      ),
      // Only with exactly one mark: editing two terms at once has no meaning,
      // and an action that is sometimes ignored is worse than one that is
      // visibly unavailable.
      if (single != null)
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit ${single.term}',
          onPressed: () => _openSheet(initial: single),
        ),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete selected',
        onPressed: _viewModel.selectedCount == 0 ? null : _confirmDelete,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final selecting = _viewModel.isSelecting;

        return Scaffold(
          appBar: AppBar(
            leading: selecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Done',
                    onPressed: _viewModel.endSelection,
                  )
                : null,
            title: Text(
              selecting
                  ? '${_viewModel.selectedCount} selected'
                  : widget.title,
            ),
            actions: selecting
                ? _selectionActions()
                : [
                    // Hidden while there is nothing to select, so the bar does
                    // not offer a mode the empty state cannot enter.
                    if (!_viewModel.isEmpty && _viewModel.loadError == null)
                      TextButton(
                        onPressed: _viewModel.beginSelection,
                        child: const Text('Edit'),
                      ),
                    ...widget.actions,
                  ],
          ),
          body: _VocabListBody(
            viewModel: _viewModel,
            onBeginSelection: _viewModel.beginSelection,
          ),
          // Adding is not part of selecting, and a button floating over the
          // rows being marked would only be in the way.
          floatingActionButton: selecting
              ? null
              : FloatingActionButton(
                  onPressed: _openSheet,
                  tooltip: 'Add vocabulary',
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}

/// Picks the right state to render: loading, error, empty, or the list itself.
class _VocabListBody extends StatelessWidget {
  const _VocabListBody({required this.viewModel, required this.onBeginSelection});

  final VocabListViewModel viewModel;
  final void Function(String id) onBeginSelection;

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
          isSelecting: viewModel.isSelecting,
          isSelected: viewModel.isSelected(vocab.id),
          onToggle: () => viewModel.toggleSelection(vocab.id),
          onBeginSelection: () => onBeginSelection(vocab.id),
        );
      },
    );
  }
}
