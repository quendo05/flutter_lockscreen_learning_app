import 'package:flutter/material.dart';

import '../../../domain/models/scheduled_vocab.dart';

/// The term currently claiming the lock screen, and when it hands over.
class NextUpCard extends StatelessWidget {
  const NextUpCard({required this.scheduled, this.followingAt, super.key});

  final ScheduledVocab scheduled;
  final DateTime? followingAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vocab = scheduled.vocab;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On your lock screen',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text(
            vocab.term,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 4),
          Text(
            vocab.translation,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
          if (followingAt != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  // TimeOfDay respects the device's 12/24-hour preference.
                  'Changes at ${TimeOfDay.fromDateTime(followingAt!).format(context)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
