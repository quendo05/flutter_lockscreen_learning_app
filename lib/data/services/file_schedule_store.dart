import 'dart:convert';
import 'dart:io';

import '../../domain/models/published_schedule.dart';
import 'schedule_store.dart';

/// A [ScheduleStore] that writes the queue to one JSON file.
///
/// The write goes to a temporary neighbour first and is then renamed over the
/// real file. Rename is atomic on both platforms, so a widget reading at the
/// wrong moment sees either the previous queue or the new one, never half of
/// one — which a plain overwrite could not promise.
class FileScheduleStore implements ScheduleStore {
  const FileScheduleStore(this.path);

  /// Where the native side expects to find the queue.
  final String path;

  @override
  Future<void> write(PublishedSchedule schedule) async {
    final file = File(path);
    await file.parent.create(recursive: true);

    final staged = File('$path.writing');
    await staged.writeAsString(jsonEncode(schedule.toJson()), flush: true);
    await staged.rename(path);
  }
}
