import 'package:flutter/material.dart';

import '../../../domain/models/vocab.dart';

/// A single row of the vocabulary list.
///
/// Carries no delete affordance of its own. A row that can destroy itself puts
/// the most damaging action of the screen one stray tap away from the most
/// common one, which is why removing a term now goes through selection mode.
class VocabListTile extends StatelessWidget {
  const VocabListTile({
    required this.vocab,
    required this.isSelecting,
    required this.isSelected,
    required this.onToggle,
    required this.onBeginSelection,
    super.key,
  });

  final Vocab vocab;

  /// Whether the list is marking entries. Decides which of the two rows below
  /// is drawn.
  final bool isSelecting;
  final bool isSelected;

  /// Marks or unmarks this row.
  final VoidCallback onToggle;

  /// Starts selection mode with this row already marked — the long press.
  final VoidCallback onBeginSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(vocab.term, style: theme.textTheme.bodyLarge);
    final subtitle = Text(vocab.translation);

    if (isSelecting) {
      // A CheckboxListTile rather than a ListTile holding a Checkbox: the row
      // is then one control to a screen reader, announced with its term and
      // its checked state, instead of a label sitting beside a nameless box.
      return CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
        title: title,
        subtitle: subtitle,
      );
    }

    return ListTile(
      title: title,
      subtitle: subtitle,
      // The platform gesture for "I want to act on these". The Edit button in
      // the bar does the same thing for anyone who does not think to try it.
      onLongPress: onBeginSelection,
    );
  }
}
