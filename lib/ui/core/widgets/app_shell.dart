import 'package:flutter/material.dart';

import '../../../data/repositories/deck_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/vocab_repository.dart';
import '../../../domain/models/deck.dart';
import '../../deck_list/view_models/deck_list_view_model.dart';
import '../../deck_list/widgets/deck_list_screen.dart';
import '../../home/view_models/home_view_model.dart';
import '../../home/widgets/home_screen.dart';
import '../../vocab_list/widgets/deck_vocab_page.dart';

/// Holds the navigation bar and swaps between the app's destinations.
///
/// Each destination keeps its own app bar and floating action button, which is
/// the Material arrangement: the shell owns only the navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.vocabRepository,
    required this.deckRepository,
    required this.settingsRepository,
    super.key,
  });

  final VocabRepository vocabRepository;
  final DeckRepository deckRepository;
  final SettingsRepository settingsRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeIndex = 0;
  static const _decksIndex = 1;

  late final HomeViewModel _homeViewModel;
  late final DeckListViewModel _deckListViewModel;

  int _selectedIndex = _homeIndex;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel(
      vocabRepository: widget.vocabRepository,
      deckRepository: widget.deckRepository,
      settingsRepository: widget.settingsRepository,
    );
    _deckListViewModel = DeckListViewModel(
      deckRepository: widget.deckRepository,
      vocabRepository: widget.vocabRepository,
      settingsRepository: widget.settingsRepository,
    );
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    _deckListViewModel.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  /// Opens a deck, then reloads the list so its term count reflects anything
  /// added while it was open.
  Future<void> _openDeck(Deck deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DeckVocabPage(deck: deck, vocabRepository: widget.vocabRepository),
      ),
    );
    await _deckListViewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only the chosen destination is built. Rebuilding on every switch keeps
      // the home summary honest after a term is added on the other tab, at the
      // cost of scroll position — a fair trade for two short screens.
      body: switch (_selectedIndex) {
        _decksIndex => DeckListScreen(
          viewModel: _deckListViewModel,
          onOpenDeck: _openDeck,
        ),
        _ => HomeScreen(
          viewModel: _homeViewModel,
          onBrowseVocabulary: () => _select(_decksIndex),
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Decks',
          ),
        ],
      ),
    );
  }
}
