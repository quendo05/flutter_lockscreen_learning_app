import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/data/services/file_schedule_store.dart';
import 'package:lockscreen_learning_app/domain/models/deck.dart';
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

  PublishedSchedule schedule({String term = 'el libro'}) =>
      PublishedSchedule.of(
        generatedAt: DateTime.utc(2026, 1, 1, 9),
        deck: Deck(
          id: 'd1',
          name: 'Spanish basics',
          sourceLanguage: 'es',
          targetLanguage: 'de',
          displayInterval: const Duration(hours: 3),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        upcoming: [
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

  group('reading back', () {
    test('returns nothing before anything has been published', () async {
      final store = FileScheduleStore(pathIn(tempDir));

      expect(await store.read(), isNull);
    });

    test('returns the queue that was written', () async {
      final store = FileScheduleStore(pathIn(tempDir));
      await store.write(schedule(term: 'el libro'));

      final restored = await store.read();

      expect(restored!.deckName, 'Spanish basics');
      expect(restored.entries.single.term, 'el libro');
    });

    test('treats an unreadable file as nothing published, so a truncated '
        'write cannot stop the app starting', () async {
      final path = pathIn(tempDir);
      await File(path).writeAsString('{"schemaVersion": 1, "entri');

      expect(await FileScheduleStore(path).read(), isNull);
    });
  });
}
