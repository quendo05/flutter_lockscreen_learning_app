import 'package:flutter/material.dart';

import '../../../config/defaults.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/language_field.dart';

/// Reports a deck to create.
///
/// Shaped to match `DeckListViewModel.createDeck` so the sheet can be wired
/// straight to it, with no adapter in between.
typedef CreateDeck = void Function(
  String name, {
  required String sourceLanguage,
  required String targetLanguage,
});

/// Bottom sheet for naming a new deck and choosing the pair it is studied in.
///
/// The pair is asked for here rather than left to the settings screen because
/// terms are stamped with their deck's pair as they are added — a deck that
/// starts in the wrong pair mislabels everything saved before anyone notices.
class CreateDeckSheet extends StatefulWidget {
  const CreateDeckSheet({required this.onSubmit, super.key});

  final CreateDeck onSubmit;

  @override
  State<CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends State<CreateDeckSheet> {
  final _controller = TextEditingController();

  /// Prefilled with the app's defaults, so someone learning the pair the app
  /// already assumes only has to name the deck.
  String _sourceLanguage = defaultSourceLanguage;
  String _targetLanguage = defaultTargetLanguage;

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

    widget.onSubmit(
      _controller.text,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
    );
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
        LanguageField(
          key: const Key('source-language-field'),
          label: 'Language you are learning',
          helperText: 'The terms in this deck will be written in it',
          value: _sourceLanguage,
          onSelected: (code) => setState(() => _sourceLanguage = code),
        ),
        LanguageField(
          key: const Key('target-language-field'),
          label: 'Language you understand',
          helperText: 'The translations will be written in it',
          value: _targetLanguage,
          onSelected: (code) => setState(() => _targetLanguage = code),
        ),
      ],
    );
  }
}
