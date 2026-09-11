import 'package:flutter/foundation.dart';

import '../../domain/models/published_schedule.dart';
import 'schedule_store.dart';
import 'widget_refresher.dart';

/// A [ScheduleStore] that tells the widget once the queue is on disk.
///
/// A decorator rather than a second call in the view model: publishing a queue
/// and redrawing what shows it are one event, and a caller that had to
/// remember both could remember only the first. Wrapping the store makes that
/// impossible, and leaves every existing caller untouched.
class NotifyingScheduleStore implements ScheduleStore {
  const NotifyingScheduleStore({
    required this._store,
    required this._refresher,
  });

  final ScheduleStore _store;
  final WidgetRefresher _refresher;

  @override
  Future<void> write(PublishedSchedule schedule) async {
    // Strictly after the write. A widget told to read early would read the
    // queue it already has and then sit on it until its next update.
    await _store.write(schedule);

    try {
      await _refresher.refresh();
    } on Object catch (error) {
      // A widget that did not hear about the write is stale, not broken: it
      // picks the new queue up on its next update either way. Reporting the
      // write as failed over it would be the worse trade, because the caller
      // would then believe nothing was published at all.
      debugPrint('NotifyingScheduleStore: could not refresh the widget: $error');
    }
  }

  @override
  Future<PublishedSchedule?> read() => _store.read();
}
