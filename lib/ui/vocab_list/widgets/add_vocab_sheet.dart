import 'package:flutter/material.dart';

/// Bottom sheet for entering a single new vocabulary pair.
///
/// Collects input only — validation and storage belong to the view model, so
/// the same rules apply however an entry is created.
class AddVocabSheet extends StatefulWidget {
  const AddVocabSheet({required this.onSubmit, super.key});

  final void Function(String term, String translation) onSubmit;

  @override
  State<AddVocabSheet> createState() => _AddVocabSheetState();
}

class _AddVocabSheetState extends State<AddVocabSheet> {
  final _termController = TextEditingController();
  final _translationController = TextEditingController();

  @override
  void dispose() {
    _termController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_termController.text, _translationController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Lifts the sheet clear of the on-screen keyboard.
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New vocabulary', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            key: const Key('term-field'),
            controller: _termController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Term',
              helperText: 'In the language you are learning',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('translation-field'),
            controller: _translationController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Translation',
              helperText: 'In the language you already speak',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
    );
  }
}
