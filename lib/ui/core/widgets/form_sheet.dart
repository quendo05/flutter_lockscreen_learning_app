import 'package:flutter/material.dart';

/// The frame the app's bottom-sheet forms share.
///
/// Holds the parts each sheet would otherwise have to get right on its own:
/// clearance for the on-screen keyboard, and a submit button that stays
/// unavailable until the form can actually be submitted, so the user is never
/// invited to submit something that will only be rejected.
class FormSheet extends StatelessWidget {
  const FormSheet({
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final String title;

  /// The inputs, stacked in order. The spacing between them is supplied here
  /// so every sheet in the app is spaced the same way.
  final List<Widget> fields;

  final String submitLabel;

  /// Null while the form cannot be submitted, which disables the button.
  final VoidCallback? onSubmit;

  static const _edge = 24.0;
  static const _fieldGap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet clear of the on-screen keyboard.
      padding: EdgeInsets.only(
        left: _edge,
        right: _edge,
        top: _edge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + _edge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          for (final field in fields) ...[
            const SizedBox(height: _fieldGap),
            field,
          ],
          const SizedBox(height: _edge),
          FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
        ],
      ),
    );
  }
}
