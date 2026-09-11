import 'package:flutter/material.dart';

import '../../../domain/models/deck.dart';
import '../../core/widgets/language_field.dart';
import '../view_models/deck_settings_view_model.dart';

/// What [DeckSettingsScreen] pops with.
///
/// A type rather than a nullable [Deck], because the page beneath has to tell
/// three outcomes apart: the deck changed, the deck is gone, or the user
/// simply came back. A deleted deck means that page has nothing left to show.
sealed class DeckSettingsOutcome {
  const DeckSettingsOutcome();
}

/// The deck was edited and stored.
class DeckSaved extends DeckSettingsOutcome {
  const DeckSaved(this.deck);

  final Deck deck;
}

/// The deck, and every term that was in it, is gone.
class DeckDeleted extends DeckSettingsOutcome {
  const DeckDeleted();
}

/// One deck's settings: its name, the pair it is studied in, its pace, and
/// the way to get rid of it.
///
/// Pops with a [DeckSettingsOutcome] so the page beneath can show a new name,
/// stamp new terms with a new pair, or close itself when the deck is gone.
class DeckSettingsScreen extends StatefulWidget {
  const DeckSettingsScreen({required this.viewModel, super.key});

  final DeckSettingsViewModel viewModel;

  @override
  State<DeckSettingsScreen> createState() => _DeckSettingsScreenState();
}

class _DeckSettingsScreenState extends State<DeckSettingsScreen> {
  late final TextEditingController _name;

  /// Held as codes rather than as controllers: the pickers hand back a code
  /// from a fixed list, so there is no text to keep or to parse.
  late String _sourceLanguage;
  late String _targetLanguage;

  late double _intervalHours;

  @override
  void initState() {
    super.initState();
    final deck = widget.viewModel.deck;
    _name = TextEditingController(text: deck.name)..addListener(_onChanged);
    _sourceLanguage = deck.sourceLanguage;
    _targetLanguage = deck.targetLanguage;
    _intervalHours = deck.displayInterval.inHours
        .clamp(minDisplayIntervalHours, maxDisplayIntervalHours)
        .toDouble();

    // Whether this deck may be deleted, and what would go with it, is not
    // knowable from the deck alone.
    widget.viewModel.addListener(_onChanged);
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    _name.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// Only the name can be left unusable now. A picker cannot report a
  /// language it was not offering, so neither language needs guarding here.
  bool get _canSave => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    final saved = await widget.viewModel.save(
      name: _name.text,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      intervalHours: _intervalHours.round(),
    );

    if (!mounted) return;

    final message = widget.viewModel.validationMessage;
    if (saved == null && message != null) {
      widget.viewModel.clearValidationMessage();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    Navigator.of(context).pop(DeckSaved(saved!));
  }

  /// Asks before deleting, because nothing here can be undone and the
  /// terms inside go too.
  Future<void> _confirmDelete() async {
    final terms = widget.viewModel.termCount ?? 0;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this deck?'),
        content: Text(
          terms == 0
              ? '${widget.viewModel.deck.name} will be deleted. This '
                    'cannot be undone.'
              : '${widget.viewModel.deck.name} and its $terms '
                    '${terms == 1 ? 'term' : 'terms'} will be deleted. '
                    'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (agreed != true || !mounted) return;

    final deleted = await widget.viewModel.delete();
    if (!mounted) return;

    if (!deleted) {
      final message = widget.viewModel.validationMessage;
      if (message != null) {
        widget.viewModel.clearValidationMessage();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    Navigator.of(context).pop(const DeckDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = _intervalHours.round();

    return Scaffold(
      appBar: AppBar(title: const Text('Deck settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            key: const Key('deck-name-field'),
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Deck name'),
          ),
          const SizedBox(height: 32),
          Text('Languages', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          LanguageField(
            key: const Key('source-language-field'),
            label: 'Language you are learning',
            helperText: 'The terms in this deck are written in it',
            value: _sourceLanguage,
            onSelected: (code) => setState(() => _sourceLanguage = code),
          ),
          const SizedBox(height: 16),
          LanguageField(
            key: const Key('target-language-field'),
            label: 'Language you understand',
            helperText: 'The translations are written in it',
            value: _targetLanguage,
            onSelected: (code) => setState(() => _targetLanguage = code),
          ),
          const SizedBox(height: 32),
          Text('Pace', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'A new term every $hours ${hours == 1 ? 'hour' : 'hours'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            // Bounded rather than free text, so an unusable interval cannot be
            // entered in the first place.
            min: minDisplayIntervalHours.toDouble(),
            max: maxDisplayIntervalHours.toDouble(),
            divisions: maxDisplayIntervalHours - minDisplayIntervalHours,
            value: _intervalHours,
            label: '$hours h',
            onChanged: (value) => setState(() => _intervalHours = value),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          _DeleteSection(
            canDelete: widget.viewModel.canDelete,
            onDelete: _confirmDelete,
          ),
        ],
      ),
    );
  }
}

/// The way to get rid of a deck, set apart from the settings above it.
///
/// Kept last and behind a divider because it is the one thing on this screen
/// that cannot be undone, and outlined rather than filled so it does not
/// compete with Save for the eye.
class _DeleteSection extends StatelessWidget {
  const _DeleteSection({required this.canDelete, required this.onDelete});

  final bool canDelete;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: canDelete ? onDelete : null,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete deck'),
          style: OutlinedButton.styleFrom(
            // Named by the theme rather than by a colour of its own, so it
            // still reads as destructive in both light and dark.
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // Said in words as well as shown by the disabled button: a control
          // that is simply greyed out leaves the user guessing why.
          canDelete
              ? 'The terms in this deck are deleted with it.'
              : 'This is your only deck, so it cannot be deleted.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
