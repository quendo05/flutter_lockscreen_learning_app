import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/data/services/notifying_schedule_store.dart';
import 'package:nagara/data/services/widget_refresher.dart';
import 'package:nagara/domain/models/deck.dart';
import 'package:nagara/domain/models/published_schedule.dart';

import '../../support/schedule_store_doubles.dart';

/// Counts the pokes, so a test can tell one from none and from two.
class RecordingWidgetRefresher implements WidgetRefresher {
  int refreshes = 0;

  @override
  Future<void> refresh() async => refreshes++;
}

class FailingWidgetRefresher implements WidgetRefresher {
  @override
  Future<void> refresh() async => throw Exception('no widget placed');
}

void main() {
  PublishedSchedule schedule() => PublishedSchedule.of(
    generatedAt: DateTime.utc(2026, 1, 1, 9),
    deck: Deck(
      id: 'd1',
      name: 'Spanish basics',
      sourceLanguage: 'es',
      targetLanguage: 'de',
      displayInterval: const Duration(hours: 3),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    upcoming: const [],
  );

  test('refreshes the widget after a write, so it redraws from the new queue', () async {
    final inner = RecordingScheduleStore();
    final refresher = RecordingWidgetRefresher();

    await NotifyingScheduleStore(
      store: inner,
      refresher: refresher,
    ).write(schedule());

    expect(inner.published, hasLength(1));
    expect(refresher.refreshes, 1);
  });

  test('does not refresh when the write failed, so the widget keeps the queue it can still read', () async {
    final refresher = RecordingWidgetRefresher();

    await expectLater(
      NotifyingScheduleStore(
        store: FailingScheduleStore(),
        refresher: refresher,
      ).write(schedule()),
      throwsException,
    );

    expect(refresher.refreshes, 0);
  });

  test('reports a write as done when only the refresh failed, because the queue is on disk', () async {
    final inner = RecordingScheduleStore();

    await NotifyingScheduleStore(
      store: inner,
      refresher: FailingWidgetRefresher(),
    ).write(schedule());

    expect(inner.published, hasLength(1));
  });

  test('reads straight through, so the app sees what it published', () async {
    final inner = RecordingScheduleStore();
    final store = NotifyingScheduleStore(
      store: inner,
      refresher: RecordingWidgetRefresher(),
    );

    await store.write(schedule());

    expect(await store.read(), inner.last);
  });
}
