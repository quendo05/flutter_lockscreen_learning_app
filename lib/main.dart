import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'data/repositories/sqflite_vocab_repository.dart';
import 'data/repositories/vocab_repository.dart';
import 'data/services/app_database.dart';
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
Future<LockscreenLearningApp> _buildApp() async {
  if (kIsWeb) {
    return LockscreenLearningApp(
      vocabRepository: InMemoryVocabRepository(),
      // On device the schema seeds this deck; in memory nothing does, so the
      // app would otherwise start with nowhere to save.
      deckRepository: InMemoryDeckRepository(
        initialDecks: [
          Deck(
            id: defaultDeckId,
            name: defaultDeckName,
            createdAt: DateTime.now().toUtc(),
          ),
        ],
      ),
      settingsRepository: InMemorySettingsRepository(),
    );
  }

  final directory = await getDatabasesPath();
  final database = await AppDatabase.open(p.join(directory, 'vocab.db'));

  return LockscreenLearningApp(
    vocabRepository: SqfliteVocabRepository(database),
    deckRepository: SqfliteDeckRepository(database),
    // The interval and the active deck are not persisted yet, so they start at
    // their defaults on every launch.
    settingsRepository: InMemorySettingsRepository(),
  );
}

class LockscreenLearningApp extends StatelessWidget {
  const LockscreenLearningApp({
    required this.vocabRepository,
    required this.deckRepository,
    required this.settingsRepository,
    super.key,
  });

  final VocabRepository vocabRepository;
  final DeckRepository deckRepository;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: _themeFor(Brightness.light),
      darkTheme: _themeFor(Brightness.dark),
      home: AppShell(
        vocabRepository: vocabRepository,
        deckRepository: deckRepository,
        settingsRepository: settingsRepository,
      ),
    );
  }

  static ThemeData _themeFor(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        // Deliberately not the default indigo — a muted green reads as calm
        // study material rather than as a generic template app.
        seedColor: const Color(0xFF3A6B5C),
        brightness: brightness,
      ),
    );
  }
}
