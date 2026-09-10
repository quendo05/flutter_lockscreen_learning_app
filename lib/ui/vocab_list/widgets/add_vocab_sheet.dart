import 'package:flutter/material.dart';

import '../../core/widgets/form_sheet.dart';

/// Bottom sheet for entering a single new vocabulary pair.
///
/// Guides the user towards a saveable entry: a field they leave behind empty
/// says so immediately, rather than waiting for the save to be rejected.
///
/// The view model still enforces the same rule, since an entry could also
/// arrive from an import or the translation service later on. This is the
/// affordance, not the enforcement.
class AddVocabSheet extends StatefulWidget {
  const AddVocabSheet({required this.onSubmit, super.key});

  final void Function(String term, String translation) onSubmit;

  @override
  State<AddVocabSheet> createState() => _AddVocabSheetState();
}

class _AddVocabSheetState extends State<AddVocabSheet> {
  final _termController = TextEditingController();
  final _translationController = TextEditingController();
  final _termFocus = FocusNode();
  final _translationFocus = FocusNode();

  /// A field only complains once the user has actually left it behind, so the
  /// form does not open already covered in warnings.
  bool _termVisited = false;
  bool _translationVisited = false;

  @override
  void initState() {
    super.initState();
    _termController.addListener(_onChanged);
    _translationController.addListener(_onChanged);
    _termFocus.addListener(
      () => _onFocusLost(_termFocus, () => _termVisited = true),
    );
    _translationFocus.addListener(
      () => _onFocusLost(_translationFocus, () => _translationVisited = true),
    );
  }

  @override
  void dispose() {
    _termController.dispose();
    _translationController.dispose();
    _termFocus.dispose();
    _translationFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onFocusLost(FocusNode node, VoidCallback markVisited) {
    if (node.hasFocus) return;
    setState(markVisited);
  }

  String get _term => _termController.text.trim();
  String get _translation => _translationController.text.trim();

  bool get _canSave => _term.isNotEmpty && _translation.isNotEmpty;

  String? _errorFor({required bool visited, required String value}) =>
      visited && value.isEmpty ? 'Required' : null;

  void _submit() {
    if (!_canSave) return;

    widget.onSubmit(_termController.text, _translationController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'New vocabulary',
      submitLabel: 'Save',
      onSubmit: _canSave ? _submit : null,
      fields: [
        TextField(
          key: const Key('term-field'),
          controller: _termController,
          focusNode: _termFocus,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _translationFocus.requestFocus(),
          decoration: InputDecoration(
            labelText: 'Term',
            helperText: 'In the language you are learning',
            errorText: _errorFor(visited: _termVisited, value: _term),
          ),
        ),
        TextField(
          key: const Key('translation-field'),
          controller: _translationController,
          focusNode: _translationFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Translation',
            helperText: 'In the language you already speak',
            errorText: _errorFor(
              visited: _translationVisited,
              value: _translation,
            ),
          ),
        ),
      ],
    );
  }
}
