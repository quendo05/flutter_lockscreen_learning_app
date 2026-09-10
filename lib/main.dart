import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'data/repositories/in_memory_vocab_repository.dart';
import 'data/repositories/sqflite_vocab_repository.dart';
import 'data/repositories/vocab_repository.dart';
import 'ui/vocab_list/view_models/vocab_list_view_model.dart';
import 'ui/vocab_list/widgets/vocab_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(LockscreenLearningApp(vocabRepository: await openVocabRepository()));
}

/// Opens the store the app should use on this platform.
///
/// sqflite has no web implementation. The browser build exists only for quick
/// UI iteration, so there it falls back to a store that does not persist
/// rather than failing to start.
Future<VocabRepository> openVocabRepository() async {
  if (kIsWeb) return InMemoryVocabRepository();

  final directory = await getDatabasesPath();
  return SqfliteVocabRepository.openAt(p.join(directory, 'vocab.db'));
}

class LockscreenLearningApp extends StatelessWidget {
  const LockscreenLearningApp({required this.vocabRepository, super.key});

  final VocabRepository vocabRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lockscreen Learning',
      theme: _themeFor(Brightness.light),
      darkTheme: _themeFor(Brightness.dark),
      home: VocabListScreen(
        viewModel: VocabListViewModel(repository: vocabRepository),
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
