import 'package:flutter/material.dart';

/// Bottom sheet for naming a new deck.
///
/// Create stays unavailable until the name has content, so the user cannot
/// submit something that will only be rejected afterwards.
class CreateDeckSheet extends StatefulWidget {
  const CreateDeckSheet({required this.onSubmit, super.key});

  final ValueChanged<String> onSubmit;

  @override
  State<CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends State<CreateDeckSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canCreate => _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_canCreate) return;

    widget.onSubmit(_controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
          Text('New deck', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            key: const Key('deck-name-field'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Name',
              helperText: 'For example: Spanish basics, or Travel',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canCreate ? _submit : null,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
