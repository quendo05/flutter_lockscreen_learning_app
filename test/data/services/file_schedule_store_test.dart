import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/services/file_schedule_store.dart';
import 'package:lockscreen_learning_app/domain/models/published_schedule.dart';
import 'package:lockscreen_learning_app/domain/models/scheduled_vocab.dart';
import 'package:lockscreen_learning_app/domain/models/vocab.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('schedule_store');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  PublishedSchedule schedule({String term = 'el libro'}) => PublishedSchedule(
    generatedAt: DateTime.utc(2026, 1, 1, 9),
    deckId: 'd1',
    deckName: 'Spanish basics',
    sourceLanguage: 'es',
    targetLanguage: 'de',
    interval: const Duration(hours: 3),
    entries: [
      ScheduledVocab(
        showAt: DateTime.utc(2026, 1, 1, 9),
        vocab: Vocab(
          id: 'v1',
          deckId: 'd1',
          term: term,
          translation: 'das Buch',
          sourceLanguage: 'es',
          targetLanguage: 'de',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ),
    ],
  );

  String pathIn(Directory dir) => p.join(dir.path, 'schedule.json');

  test('writes a payload the native side can parse', () async {
    final path = pathIn(tempDir);

    await FileScheduleStore(path).write(schedule());

    final decoded =
        jsonDecode(await File(path).readAsString()) as Map<String, Object?>;

    expect(decoded['schemaVersion'], PublishedSchedule.version);
    expect(decoded['deckName'], 'Spanish basics');
    expect(decoded['entries']! as List<Object?>, hasLength(1));
  });

  test('replaces the previous queue rather than adding to it', () async {
    final path = pathIn(tempDir);
    final store = FileScheduleStore(path);

    await store.write(schedule(term: 'first'));
    await store.write(schedule(term: 'second'));

    final decoded =
        jsonDecode(await File(path).readAsString()) as Map<String, Object?>;
    final entries = decoded['entries']! as List<Object?>;

    expect(entries, hasLength(1));
    expect((entries.single! as Map<String, Object?>)['term'], 'second');
  });

  test('creates the directory it was pointed at', () async {
    final path = p.join(tempDir.path, 'nested', 'dir', 'schedule.json');

    await FileScheduleStore(path).write(schedule());

    expect(File(path).existsSync(), isTrue);
  });

  test('leaves no half-written file behind, because the widget may read at any '
      'moment', () async {
    final path = pathIn(tempDir);

    await FileScheduleStore(path).write(schedule());

    final leftovers = tempDir
        .listSync()
        .map((e) => p.basename(e.path))
        .where((name) => name != 'schedule.json');

    expect(leftovers, isEmpty);
  });
}
