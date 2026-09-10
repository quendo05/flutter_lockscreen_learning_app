/// The deck the v1 -> v2 migration puts pre-existing terms into, and the deck
/// a fresh install starts with. Having a known id means there is always a real
/// deck to add terms to.
const defaultDeckId = 'default';

/// The name shown for [defaultDeckId].
const defaultDeckName = 'My vocabulary';

/// A named collection of vocabulary the user studies together.
///
/// Which deck is currently feeding the lock screen is a user preference, not a
/// property of the deck, so it lives in the settings repository. That keeps two
/// decks from ever both claiming to be active.
class Deck {
  const Deck({
    required this.id,
    required this.name,
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
        createdAt: createdAt,
      );

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Deck.fromMap(Map<String, Object?> map) => Deck(
        id: map['id']! as String,
        name: map['name']! as String,
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
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() => 'Deck($id, $name)';
}
