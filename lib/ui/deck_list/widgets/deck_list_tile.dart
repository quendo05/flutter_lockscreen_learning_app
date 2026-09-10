import 'package:flutter/material.dart';

import '../../../domain/models/deck.dart';

/// A single deck row: its name, how full it is, and whether the lock screen
/// is currently drawing from it.
class DeckListTile extends StatelessWidget {
  const DeckListTile({
    required this.deck,
    required this.termCount,
    required this.isActive,
    required this.onOpen,
    required this.onActivate,
    super.key,
  });

  final Deck deck;
  final int termCount;
  final bool isActive;
  final VoidCallback onOpen;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terms = '$termCount ${termCount == 1 ? 'term' : 'terms'}';

    return ListTile(
      title: Text(deck.name, style: theme.textTheme.bodyLarge),
      // The active deck says so in words as well as through the icon, so the
      // state does not depend on colour alone.
      subtitle: Text(isActive ? '$terms · on your lock screen' : terms),
      onTap: onOpen,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: isActive ? theme.colorScheme.primary : null,
            ),
            tooltip: isActive
                ? '${deck.name} is on your lock screen'
                : 'Use ${deck.name} for your lock screen',
            onPressed: isActive ? null : onActivate,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
