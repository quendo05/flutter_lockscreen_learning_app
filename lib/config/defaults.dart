/// What the app does out of the box, until a settings screen lets the user
/// change it.
///
/// Gathered here rather than beside whichever code needed them first, so the
/// starting behaviour can be read off one file.
library;

/// How long one term holds the lock screen before the next takes over.
const defaultDisplayInterval = Duration(hours: 3);

/// The language the terms themselves are written in, as a BCP 47 code.
const defaultSourceLanguage = 'en';

/// The language the translations are written in, as a BCP 47 code.
const defaultTargetLanguage = 'de';
