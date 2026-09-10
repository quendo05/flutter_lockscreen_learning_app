/// A single vocabulary entry the user is learning.
///
/// [term] is written in the language being learned, [translation] in the
/// language the user already speaks. Both may be phrases, not just single
/// words, which is why this is a "term" rather than a "word".
class Vocab {
  const Vocab({
    required this.id,
    required this.term,
    required this.translation,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
    this.lastShownAt,
    this.timesShown = 0,
  });

  final String id;
  final String term;
  final String translation;

  /// BCP 47 language codes, e.g. 'es' and 'de'.
  final String sourceLanguage;
  final String targetLanguage;

  final DateTime createdAt;

  /// Null until the entry has been shown on the lock screen at least once.
  /// Together with [timesShown] this drives which entry comes up next.
  final DateTime? lastShownAt;
  final int timesShown;

  /// Replaces the named fields and keeps the rest.
  ///
  /// Passing null for [lastShownAt] means "leave unchanged", not "clear it" —
  /// nothing needs to clear it yet, so the simpler signature wins.
  Vocab copyWith({
    String? id,
    String? term,
    String? translation,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? createdAt,
    DateTime? lastShownAt,
    int? timesShown,
  }) {
    return Vocab(
      id: id ?? this.id,
      term: term ?? this.term,
      translation: translation ?? this.translation,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
      lastShownAt: lastShownAt ?? this.lastShownAt,
      timesShown: timesShown ?? this.timesShown,
    );
  }

  /// Timestamps become UTC epoch milliseconds so the map drops straight into
  /// a database row or the shared store the native widgets read.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'term': term,
      'translation': translation,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastShownAt': lastShownAt?.millisecondsSinceEpoch,
      'timesShown': timesShown,
    };
  }

  factory Vocab.fromMap(Map<String, Object?> map) {
    final lastShownAt = map['lastShownAt'] as int?;

    return Vocab(
      id: map['id']! as String,
      term: map['term']! as String,
      translation: map['translation']! as String,
      sourceLanguage: map['sourceLanguage']! as String,
      targetLanguage: map['targetLanguage']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt']! as int,
        isUtc: true,
      ),
      lastShownAt: lastShownAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastShownAt, isUtc: true),
      timesShown: map['timesShown']! as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Vocab &&
        other.id == id &&
        other.term == term &&
        other.translation == translation &&
        other.sourceLanguage == sourceLanguage &&
        other.targetLanguage == targetLanguage &&
        other.createdAt == createdAt &&
        other.lastShownAt == lastShownAt &&
        other.timesShown == timesShown;
  }

  @override
  int get hashCode => Object.hash(
        id,
        term,
        translation,
        sourceLanguage,
        targetLanguage,
        createdAt,
        lastShownAt,
        timesShown,
      );

  @override
  String toString() => 'Vocab($id, $term → $translation)';
}
