import '../../domain/models/published_schedule.dart';

/// Where the app leaves the queue of upcoming terms for the native side.
///
/// An interface rather than a concrete file, because the two platforms do not
/// agree on where a widget may read from: on Android an app-private file is
/// enough, on iOS it has to sit in the App Group container the widget
/// extension shares. Both are a path, so one implementation covers them, but
/// the seam is here for whatever a platform turns out to need.
abstract class ScheduleStore {
  /// Replaces whatever queue was published before.
  ///
  /// May throw: publishing is a side effect of showing a screen, so callers
  /// are expected to decide for themselves whether a failure is worth
  /// interrupting the user for.
  Future<void> write(PublishedSchedule schedule);
}
