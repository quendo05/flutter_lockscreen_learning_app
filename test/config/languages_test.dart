import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/config/defaults.dart';
import 'package:lockscreen_learning_app/config/languages.dart';

void main() {
  group('supportedLanguages', () {
    test('carries no duplicate codes, so a pick is unambiguous', () {
      final codes = supportedLanguages.map((l) => l.code).toList();

      expect(codes.toSet(), hasLength(codes.length));
    });

    test('is ordered by name, so the list can be scanned alphabetically', () {
      final names = supportedLanguages.map((l) => l.name).toList();

      expect(names, equals([...names]..sort()));
    });

    test('offers the pair a fresh deck starts with', () {
      final codes = supportedLanguages.map((l) => l.code);

      expect(codes, contains(defaultSourceLanguage));
      expect(codes, contains(defaultTargetLanguage));
    });
  });

  group('languageNameFor', () {
    test('names a code the catalogue knows', () {
      expect(languageNameFor('de'), 'German');
    });

    test('falls back to the code itself, so a deck saved when the field was '
        'free text still shows what it holds', () {
      expect(languageNameFor('elvish'), 'elvish');
    });
  });

  group('matchesLanguageSearch', () {
    test('matches on the name, which is what is on screen', () {
      expect(
        matchesLanguageSearch(const Language('de', 'German'), 'germ'),
        isTrue,
      );
    });

    test('matches on the code, which is what gets stored', () {
      expect(
        matchesLanguageSearch(const Language('de', 'German'), 'de'),
        isTrue,
      );
    });

    test('ignores case and surrounding space', () {
      expect(
        matchesLanguageSearch(const Language('de', 'German'), '  GERMAN '),
        isTrue,
      );
    });

    test('rejects what matches neither', () {
      expect(
        matchesLanguageSearch(const Language('de', 'German'), 'xyz'),
        isFalse,
      );
    });
  });
}
