import 'package:lockscreen_learning_app/data/services/schedule_store.dart';
import 'package:lockscreen_learning_app/domain/models/published_schedule.dart';

/// A store that keeps what it was handed, for asserting on what was published.
class RecordingScheduleStore implements ScheduleStore {
  RecordingScheduleStore({this.previous});

  final published = <PublishedSchedule>[];

  /// What a read returns until something is written.
  PublishedSchedule? previous;

  PublishedSchedule get last => published.last;

  @override
  Future<void> write(PublishedSchedule schedule) async {
    published.add(schedule);
    previous = schedule;
  }

  @override
  Future<PublishedSchedule?> read() async => previous;
}

/// A store whose every write fails, for exercising the path where the lock
/// screen cannot be updated but the app still has to work.
class FailingScheduleStore implements ScheduleStore {
  @override
  Future<void> write(PublishedSchedule schedule) async =>
      throw Exception('no room on device');

  @override
  Future<PublishedSchedule?> read() async => null;
}
