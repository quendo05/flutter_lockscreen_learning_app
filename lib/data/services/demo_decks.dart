/// Three decks holding the same ten words, for trying the app out with
/// something in it.
///
/// Seeded only on request — see `main.dart` — so nothing here reaches an
/// install that did not ask for it.
///
/// The same words in three languages on purpose: it makes the deck switch
/// visible at a glance, and the Japanese deck puts a script through the lock
/// screen that a Latin-only font will not render, which is worth finding out
/// early rather than late.
library;

import '../../domain/models/deck.dart';
import '../../domain/models/vocab.dart';
import '../../utils/clock.dart';
import '../repositories/deck_repository.dart';
import '../repositories/vocab_repository.dart';

/// The ten ideas every demo deck carries, in the order they are numbered.
///
/// Kept as one list so the three decks cannot drift apart.
const _words =
    <({String german, String japanese, String english, String spanish})>[
      (
        german: 'das Wasser',
        japanese: '水 (mizu)',
        english: 'water',
        spanish: 'el agua',
      ),
      (
        german: 'das Brot',
        japanese: 'パン (pan)',
        english: 'bread',
        spanish: 'el pan',
      ),
      (
        german: 'das Haus',
        japanese: '家 (ie)',
        english: 'house',
        spanish: 'la casa',
      ),
      (
        german: 'das Buch',
        japanese: '本 (hon)',
        english: 'book',
        spanish: 'el libro',
      ),
      (
        german: 'der Freund',
        japanese: '友だち (tomodachi)',
        english: 'friend',
        spanish: 'el amigo',
      ),
      (
        german: 'der Tag',
        japanese: '日 (hi)',
        english: 'day',
        spanish: 'el día',
      ),
      (
        german: 'die Nacht',
        japanese: '夜 (yoru)',
        english: 'night',
        spanish: 'la noche',
      ),
      (
        german: 'die Katze',
        japanese: '猫 (neko)',
        english: 'cat',
        spanish: 'el gato',
      ),
      (
        german: 'der Hund',
        japanese: '犬 (inu)',
        english: 'dog',
        spanish: 'el perro',
      ),
      (
        german: 'danke',
        japanese: 'ありがとう (arigatō)',
        english: 'thank you',
        spanish: 'gracias',
      ),
    ];

/// The decks to create, each with the pace it is studied at.
///
/// Three different paces so a lock screen can be watched changing without
/// waiting a whole afternoon for the next term.
const _decks = <({String id, String name, String language, Duration interval})>[
  (
    id: 'demo-ja',
    name: 'Japanisch – Grundwortschatz',
    language: 'ja',
    interval: Duration(hours: 1),
  ),
  (
    id: 'demo-en',
    name: 'English – Basics',
    language: 'en',
    interval: Duration(hours: 2),
  ),
  (
    id: 'demo-es',
    name: 'Español – Básico',
    language: 'es',
    interval: Duration(hours: 3),
  ),
];

/// Writes the demo decks, unless they are already there.
///
/// Ids are fixed rather than generated, which is what makes running this twice
/// harmless: a second run overwrites the same rows instead of adding a second
/// set of decks beside the first.
Future<void> seedDemoDecks({
  required DeckRepository deckRepository,
  required VocabRepository vocabRepository,
  Clock? clock,
}) async {
  final now = (clock ?? DateTime.now)();

  for (var deckIndex = 0; deckIndex < _decks.length; deckIndex++) {
    final spec = _decks[deckIndex];

    await deckRepository.save(
      Deck(
        id: spec.id,
        name: spec.name,
        sourceLanguage: spec.language,
        targetLanguage: 'de',
        displayInterval: spec.interval,
        // Spaced a second apart so the decks list in the order written rather
        // than in whatever order equal timestamps happen to sort.
        createdAt: now.add(Duration(seconds: deckIndex)),
      ),
    );

    for (var i = 0; i < _words.length; i++) {
      final word = _words[i];

      await vocabRepository.save(
        Vocab(
          // Two digits so the ids sort the way the words are numbered.
          id: '${spec.id}-${(i + 1).toString().padLeft(2, '0')}',
          deckId: spec.id,
          term: switch (spec.language) {
            'ja' => word.japanese,
            'en' => word.english,
            _ => word.spanish,
          },
          translation: word.german,
          sourceLanguage: spec.language,
          targetLanguage: 'de',
          createdAt: now.add(Duration(seconds: i)),
        ),
      );
    }
  }
}
