/// Supplies the current time.
///
/// View models take one of these rather than calling [DateTime.now] directly,
/// so a test can pin the clock and assert on exact timestamps.
typedef Clock = DateTime Function();
