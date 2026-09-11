/// The languages a deck can be studied in.
///
/// Kept beside the other defaults rather than in `domain/`: a deck stores a
/// BCP 47 code and nothing in the domain needs to know what that code is
/// called, so this is the app deciding what to offer rather than a rule about
/// vocabulary.
///
/// The list is deliberately finite. The fields it replaced were free text,
/// which let a deck be saved as "spanish", "Spanish" or "es" and made two
/// decks in the same language look like two languages.
library;

/// A language the app can offer, paired with the code it is stored as.
class Language {
  const Language(this.code, this.name);

  /// The BCP 47 code written to the database. This is what a [Deck] holds.
  final String code;

  /// What the user reads. English names throughout, because the app has no
  /// localisation yet and a half-localised list would be worse than a
  /// consistent one.
  final String name;
}

/// What the pickers offer, ordered by name so the list can be scanned as well
/// as searched.
const supportedLanguages = <Language>[
  Language('af', 'Afrikaans'),
  Language('ar', 'Arabic'),
  Language('bn', 'Bengali'),
  Language('bg', 'Bulgarian'),
  Language('ca', 'Catalan'),
  Language('zh', 'Chinese'),
  Language('hr', 'Croatian'),
  Language('cs', 'Czech'),
  Language('da', 'Danish'),
  Language('nl', 'Dutch'),
  Language('en', 'English'),
  Language('et', 'Estonian'),
  Language('tl', 'Filipino'),
  Language('fi', 'Finnish'),
  Language('fr', 'French'),
  Language('de', 'German'),
  Language('el', 'Greek'),
  Language('he', 'Hebrew'),
  Language('hi', 'Hindi'),
  Language('hu', 'Hungarian'),
  Language('is', 'Icelandic'),
  Language('id', 'Indonesian'),
  Language('it', 'Italian'),
  Language('ja', 'Japanese'),
  Language('ko', 'Korean'),
  Language('lv', 'Latvian'),
  Language('lt', 'Lithuanian'),
  Language('ms', 'Malay'),
  Language('no', 'Norwegian'),
  Language('fa', 'Persian'),
  Language('pl', 'Polish'),
  Language('pt', 'Portuguese'),
  Language('ro', 'Romanian'),
  Language('ru', 'Russian'),
  Language('sr', 'Serbian'),
  Language('sk', 'Slovak'),
  Language('sl', 'Slovenian'),
  Language('es', 'Spanish'),
  Language('sw', 'Swahili'),
  Language('sv', 'Swedish'),
  Language('ta', 'Tamil'),
  Language('th', 'Thai'),
  Language('tr', 'Turkish'),
  Language('uk', 'Ukrainian'),
  Language('ur', 'Urdu'),
  Language('vi', 'Vietnamese'),
];

/// What to call [code] on screen.
///
/// Falls back to the code itself rather than to a placeholder: decks created
/// while the field was free text hold whatever was typed, and showing that
/// back is more honest than showing "Unknown".
String languageNameFor(String code) {
  for (final language in supportedLanguages) {
    if (language.code == code) return language.name;
  }
  return code;
}

/// Whether [language] should survive the search term [query].
///
/// Matches the code as well as the name, so someone who thinks in codes can
/// type `de` and someone who thinks in names can type `German`.
bool matchesLanguageSearch(Language language, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;

  return language.name.toLowerCase().contains(needle) ||
      language.code.toLowerCase().contains(needle);
}
