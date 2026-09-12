import 'package:flutter/material.dart';

import '../../../domain/models/vocab.dart';
import '../../core/widgets/form_sheet.dart';

/// Bottom sheet for entering a single vocabulary pair, new or existing.
///
/// One sheet for both, because adding and editing ask for exactly the same two
/// things and enforce the same rule. A second form would be the same fields,
/// the same validation and the same keyboard handling, kept in step by hand.
///
/// Guides the user towards a saveable entry: a field they leave behind empty
/// says so immediately, rather than waiting for the save to be rejected. The
/// view model still enforces the same rule, since an entry could also arrive
/// from an import or a translation service later on. This is the affordance,
/// not the enforcement.
class VocabSheet extends StatefulWidget {
  const VocabSheet({required this.onSubmit, this.initial, super.key});

  /// The entry being edited, or null when adding a new one. Only its text is
  /// read — the caller owns what happens to the rest of it.
  final Vocab? initial;

  final void Function(String term, String translation) onSubmit;

  @override
  State<VocabSheet> createState() => _VocabSheetState();
}

class _VocabSheetState extends State<VocabSheet> {
  late final TextEditingController _termController;
  late final TextEditingController _translationController;
  final _termFocus = FocusNode();
  final _translationFocus = FocusNode();

  /// A field only complains once the user has actually left it behind, so the
  /// form does not open already covered in warnings.
  bool _termVisited = false;
  bool _translationVisited = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _termController = TextEditingController(text: initial?.term ?? '');
    _translationController = TextEditingController(
      text: initial?.translation ?? '',
    );
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
      title: widget.initial == null ? 'New vocabulary' : 'Edit vocabulary',
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
