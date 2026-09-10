import 'package:flutter/material.dart';

import '../../../config/app_info.dart';
import '../../core/widgets/message_state.dart';
import '../view_models/home_view_model.dart';
import 'next_up_card.dart';

/// The landing screen: what the lock screen is showing, and how much
/// vocabulary stands behind it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.viewModel,
    required this.onBrowseVocabulary,
    super.key,
  });

  final HomeViewModel viewModel;

  /// Sends the user to the vocabulary list, which the shell owns.
  final VoidCallback onBrowseVocabulary;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) => _HomeBody(
          viewModel: widget.viewModel,
          onBrowseVocabulary: widget.onBrowseVocabulary,
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.viewModel, required this.onBrowseVocabulary});

  final HomeViewModel viewModel;
  final VoidCallback onBrowseVocabulary;

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

    if (viewModel.hasNoVocabulary) {
      return MessageState(
        icon: Icons.lock_outline,
        title: 'Nothing on your lock screen yet',
        message: 'Save a term and it will start appearing under your clock.',
        action: FilledButton(
          onPressed: onBrowseVocabulary,
          child: const Text('Add your first term'),
        ),
      );
    }

    final nextUp = viewModel.nextUp!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        NextUpCard(scheduled: nextUp, followingAt: viewModel.followingAt),
        const SizedBox(height: 24),
        _CollectionSummary(
          count: viewModel.vocabularyCount,
          interval: viewModel.displayInterval,
          onBrowse: onBrowseVocabulary,
        ),
      ],
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({
    required this.count,
    required this.interval,
    required this.onBrowse,
  });

  final int count;
  final Duration interval;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = interval.inHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your collection', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '$count ${count == 1 ? 'term' : 'terms'} saved',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          'A new one every $hours ${hours == 1 ? 'hour' : 'hours'}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onBrowse,
          child: const Text('Manage vocabulary'),
        ),
      ],
    );
  }
}
