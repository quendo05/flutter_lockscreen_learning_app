import 'package:flutter/material.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../home/view_models/home_view_model.dart';
import '../../home/widgets/home_screen.dart';
import '../../vocab_list/view_models/vocab_list_view_model.dart';
import '../../vocab_list/widgets/vocab_list_screen.dart';

/// Holds the navigation bar and swaps between the app's destinations.
///
/// Each destination keeps its own app bar and floating action button, which is
/// the Material arrangement: the shell owns only the navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.vocabRepository,
    required this.settingsRepository,
    super.key,
  });

  final VocabRepository vocabRepository;
  final SettingsRepository settingsRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeIndex = 0;
  static const _vocabularyIndex = 1;

  late final HomeViewModel _homeViewModel;
  late final VocabListViewModel _vocabListViewModel;

  int _selectedIndex = _homeIndex;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel(
      vocabRepository: widget.vocabRepository,
      settingsRepository: widget.settingsRepository,
    );
    _vocabListViewModel =
        VocabListViewModel(repository: widget.vocabRepository);
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    _vocabListViewModel.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only the chosen destination is built. Rebuilding on every switch keeps
      // the home summary honest after a term is added on the other tab, at the
      // cost of scroll position — a fair trade for two short screens.
      body: switch (_selectedIndex) {
        _vocabularyIndex => VocabListScreen(viewModel: _vocabListViewModel),
        _ => HomeScreen(
            viewModel: _homeViewModel,
            onBrowseVocabulary: () => _select(_vocabularyIndex),
          ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Words',
          ),
        ],
      ),
    );
  }
}
