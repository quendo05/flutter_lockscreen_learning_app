import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'config/app_info.dart';
import 'data/repositories/deck_repository.dart';
import 'data/repositories/in_memory_deck_repository.dart';
import 'data/repositories/in_memory_settings_repository.dart';
import 'data/repositories/in_memory_vocab_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/sqflite_deck_repository.dart';
import 'data/repositories/sqflite_settings_repository.dart';
import 'data/repositories/sqflite_vocab_repository.dart';
import 'data/repositories/vocab_repository.dart';
import 'data/services/app_database.dart';
import 'data/services/demo_decks.dart';
import 'data/services/file_schedule_store.dart';
import 'data/services/schedule_store.dart';
import 'domain/models/deck.dart';
import 'ui/core/widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(await _buildApp());
}

/// Assembles the app against whichever storage this platform supports.
///
/// sqflite has no web implementation. The browser build exists only for quick
/// UI iteration, so there it falls back to stores that do not persist rather
/// than failing to start.
/// Whether to write the demo decks on start:
///
/// ```sh
/// flutter run --dart-define=SEED_DEMO_DECKS=true
/// ```
///
/// A compile-time constant, so a normal build drops the seeding and the demo
/// words with it rather than shipping them and skipping over them.
const _seedDemo = bool.fromEnvironment('SEED_DEMO_DECKS');

Future<LockscreenLearningApp> _buildApp() async {
  if (kIsWeb) {
    final vocabRepository = InMemoryVocabRepository();
    // On device the schema seeds this deck; in memory nothing does, so the
    // app would otherwise start with nowhere to save.
    final deckRepository = InMemoryDeckRepository(
      initialDecks: [Deck.initial(createdAt: DateTime.now().toUtc())],
    );

    if (_seedDemo) {
      await seedDemoDecks(
        deckRepository: deckRepository,
        vocabRepository: vocabRepository,
      );
    }

    return LockscreenLearningApp(
      vocabRepository: vocabRepository,
      deckRepository: deckRepository,
      settingsRepository: InMemorySettingsRepository(),
    );
  }

  final directory = await getDatabasesPath();
  final database = await AppDatabase.open(p.join(directory, 'vocab.db'));
  final vocabRepository = SqfliteVocabRepository(database);
  final deckRepository = SqfliteDeckRepository(database);

  if (_seedDemo) {
    await seedDemoDecks(
      deckRepository: deckRepository,
      vocabRepository: vocabRepository,
    );
  }

  return LockscreenLearningApp(
    vocabRepository: vocabRepository,
    deckRepository: deckRepository,
    settingsRepository: SqfliteSettingsRepository(database),
    // Beside the database for now. The iOS widget extension will only be able
    // to read this once it moves into the App Group container the extension
    // shares, which is a change to this line and nothing else.
    scheduleStore: FileScheduleStore(p.join(directory, 'schedule.json')),
  );
}

class LockscreenLearningApp extends StatelessWidget {
  const LockscreenLearningApp({
    required this.vocabRepository,
    required this.deckRepository,
    required this.settingsRepository,
    this.scheduleStore,
    super.key,
  });

  final VocabRepository vocabRepository;
  final DeckRepository deckRepository;
  final SettingsRepository settingsRepository;
  final ScheduleStore? scheduleStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: themeFor(Brightness.light),
      darkTheme: themeFor(Brightness.dark),
      home: AppShell(
        vocabRepository: vocabRepository,
        deckRepository: deckRepository,
        settingsRepository: settingsRepository,
        scheduleStore: scheduleStore,
      ),
    );
  }

  /// Public so a test can assert the header stays distinct from the body.
  @visibleForTesting
  static ThemeData themeFor(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      // Deliberately not the default indigo — a muted green reads as calm
      // study material rather than as a generic template app.
      seedColor: const Color(0xFF3A6B5C),
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        // A tonal shade drawn from the same seed, one step up from the page
        // body. Material 3 defaults the app bar to `surface`, which is exactly
        // the body colour, so the header dissolves into the content; this is
        // what separates them. The navigation bar sits on the same container
        // shade, so the two frame the content instead of competing with it.
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        // The container shade already carries the tint; letting the elevation
        // overlay add more would darken it a second time.
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // A hairline instead of a shadow. Shadows under a header compete with
        // the content for depth and cost more to render.
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
