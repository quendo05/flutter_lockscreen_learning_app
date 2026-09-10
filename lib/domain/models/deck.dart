import '../../config/defaults.dart';

/// The deck the v1 -> v2 migration puts pre-existing terms into, and the deck
/// a fresh install starts with. Having a known id means there is always a real
/// deck to add terms to.
const defaultDeckId = 'default';

/// The name shown for [defaultDeckId].
const defaultDeckName = 'My vocabulary';

/// A named collection of vocabulary the user studies together.
///
/// A deck owns how it is studied: the language pair and how often its terms
/// reach the lock screen. Those belong here rather than in global settings
/// because they differ per deck — a Spanish deck and a French deck are not
/// learned in the same language, nor necessarily at the same pace.
///
/// Which deck is currently feeding the lock screen is the one thing that stays
/// a global preference, so two decks can never both claim to be active.
class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.displayInterval,
    required this.createdAt,
  });

  /// The deck a fresh install starts with, and the one the v1 -> v2 migration
  /// files pre-existing terms under.
  ///
  /// Built here so the seed cannot drift between the schema, the web build
  /// and the tests, which each need to produce the same deck.
  factory Deck.initial({required DateTime createdAt}) => Deck(
    id: defaultDeckId,
    name: defaultDeckName,
    sourceLanguage: defaultSourceLanguage,
    targetLanguage: defaultTargetLanguage,
    displayInterval: defaultDisplayInterval,
    createdAt: createdAt,
  );

  final String id;
  final String name;

  /// The language being learned. A deck's terms are written in it.
  final String sourceLanguage;

  /// The language the user already understands. Translations are written in it.
  final String targetLanguage;

  /// How long to wait between two of this deck's terms.
  final Duration displayInterval;

  final DateTime createdAt;

  Deck copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    Duration? displayInterval,
    DateTime? createdAt,
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    displayInterval: displayInterval ?? this.displayInterval,
    createdAt: createdAt ?? this.createdAt,
  );

  /// The interval is stored in whole minutes, which is finer than anyone needs
  /// and avoids keeping a [Duration] in a column.
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'displayIntervalMinutes': displayInterval.inMinutes,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Deck.fromMap(Map<String, Object?> map) => Deck(
    id: map['id']! as String,
    name: map['name']! as String,
    sourceLanguage: map['sourceLanguage']! as String,
    targetLanguage: map['targetLanguage']! as String,
    displayInterval: Duration(minutes: map['displayIntervalMinutes']! as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      map['createdAt']! as int,
      isUtc: true,
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is Deck &&
      other.id == id &&
      other.name == name &&
      other.sourceLanguage == sourceLanguage &&
      other.targetLanguage == targetLanguage &&
      other.displayInterval == displayInterval &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceLanguage,
    targetLanguage,
    displayInterval,
    createdAt,
  );

  @override
  String toString() => 'Deck($id, $name, $sourceLanguage -> $targetLanguage)';
}
