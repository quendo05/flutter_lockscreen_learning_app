import 'package:flutter/material.dart';

import '../../../domain/models/vocab.dart';

/// A single row of the vocabulary list.
class VocabListTile extends StatelessWidget {
  const VocabListTile({required this.vocab, required this.onDelete, super.key});

  final Vocab vocab;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(vocab.term, style: theme.textTheme.bodyLarge),
      subtitle: Text(vocab.translation),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        // Naming the term makes the button unambiguous to a screen reader,
        // which would otherwise announce a row of identical "delete" buttons.
        tooltip: 'Delete ${vocab.term}',
        onPressed: onDelete,
      ),
    );
  }
}
