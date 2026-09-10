import 'package:flutter/material.dart';

import '../../core/widgets/form_sheet.dart';

/// Bottom sheet for naming a new deck.
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
    return FormSheet(
      title: 'New deck',
      submitLabel: 'Create',
      onSubmit: _canCreate ? _submit : null,
      fields: [
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
      ],
    );
  }
}
