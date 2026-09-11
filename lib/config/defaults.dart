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

/// How many upcoming terms the app hands the lock screen at a time.
///
/// The queue has to outlast the longest plausible spell without opening the
/// app, because nothing refills it in the meantime. At the widest pace on
/// offer this is a fortnight; at the narrowest, two days.
const publishedScheduleLength = 48;
