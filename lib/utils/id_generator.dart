/// Supplies ids for newly created records.
///
/// Injected for the same reason as [Clock]: a test needs predictable ids, not
/// whatever the machine happened to produce.
typedef IdGenerator = String Function();

/// The generator used unless a test supplies its own.
///
/// Microsecond resolution makes a collision within one install implausible,
/// and base 36 keeps the id short enough to read in a database row.
String generateId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
