import 'package:flutter/material.dart';

import '../../../config/languages.dart';

/// Picks one language, by name, from a searchable list.
///
/// This replaced a plain text field. Typing the language meant the stored code
/// was whatever the user happened to write, so "es", "Spanish" and "spanish"
/// all reached the database and decks in the same language stopped looking
/// alike. Choosing from a list makes an unusable value unreachable rather than
/// something to validate afterwards.
///
/// The list is long enough that scanning it is not enough on its own, hence
/// the filter; and short enough that a full-screen picker would be overkill,
/// hence the dropdown.
class LanguageField extends StatelessWidget {
  const LanguageField({
    required this.label,
    required this.helperText,
    required this.value,
    required this.onSelected,
    super.key,
  });

  final String label;
  final String helperText;

  /// The BCP 47 code currently stored, which need not be one the catalogue
  /// knows — see [_entries].
  final String value;

  /// Reports the code to store. Only fires on a real choice, so tapping away
  /// from a half-typed search leaves the deck as it was.
  final ValueChanged<String> onSelected;

  /// How tall the menu may grow before it scrolls. Roughly six rows: enough to
  /// show that the list continues, short enough to leave the field and the
  /// keyboard visible on a phone.
  static const _menuHeight = 320.0;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: value,
      label: Text(label),
      helperText: helperText,
      leadingIcon: const Icon(Icons.translate),
      enableFilter: true,
      // Without this the field is read-only on mobile, which is where the
      // app runs — tapping would open the list but typing would do
      // nothing, leaving a long list with no way to search it.
      requestFocusOnTap: true,
      // Without this the field is only as wide as its longest entry, which
      // would leave the two pickers on a form different widths.
      expandedInsets: EdgeInsets.zero,
      menuHeight: _menuHeight,
      filterCallback: _filter,
      dropdownMenuEntries: _entries(),
      onSelected: (code) {
        if (code != null) onSelected(code);
      },
    );
  }

  /// The catalogue, preceded by [value] when the catalogue does not hold it.
  ///
  /// Without that entry a deck saved while this was a free text field would
  /// open with an empty field and lose its language on the next save.
  List<DropdownMenuEntry<String>> _entries() {
    final entries = [
      for (final language in supportedLanguages)
        DropdownMenuEntry(value: language.code, label: language.name),
    ];

    if (supportedLanguages.every((language) => language.code != value)) {
      entries.insert(
        0,
        DropdownMenuEntry(value: value, label: languageNameFor(value)),
      );
    }

    return entries;
  }

  /// Defers to [matchesLanguageSearch] so the field searches by code as well
  /// as by name, which the default label-only filter would not.
  static List<DropdownMenuEntry<String>> _filter(
    List<DropdownMenuEntry<String>> entries,
    String query,
  ) => entries
      .where(
        (entry) =>
            matchesLanguageSearch(Language(entry.value, entry.label), query),
      )
      .toList();
}
