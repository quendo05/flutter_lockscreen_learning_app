import 'package:flutter/material.dart';

import '../../../domain/models/deck.dart';
import '../../core/widgets/language_field.dart';
import '../view_models/deck_settings_view_model.dart';

/// One deck's settings: its name, the pair it is studied in, and its pace.
///
/// Pops with the saved [Deck] so the page beneath can show the new name and
/// stamp new terms with the new pair.
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
  }

  @override
  void dispose() {
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

    Navigator.of(context).pop(saved);
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
        ],
      ),
    );
  }
}
