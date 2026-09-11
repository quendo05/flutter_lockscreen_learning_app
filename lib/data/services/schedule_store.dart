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

  /// The queue published last, or null if there is none to be had.
  ///
  /// Null rather than a throw for an absent or unreadable queue: on a first
  /// run there simply is none, and a payload this app cannot parse is no more
  /// useful than an absent one. A caller catching up on what was shown should
  /// treat both the same way.
  Future<PublishedSchedule?> read();
}
