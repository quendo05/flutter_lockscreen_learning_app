import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/ui/vocab_list/widgets/add_vocab_sheet.dart';

void main() {
  final submissions = <(String, String)>[];

  setUp(submissions.clear);

  Future<void> pumpSheet(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddVocabSheet(
            onSubmit: (term, translation) =>
                submissions.add((term, translation)),
          ),
        ),
      ),
    );
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  /// Reads one field's own error, so a warning on the other field cannot be
  /// mistaken for this one.
  String? errorOn(WidgetTester tester, String fieldKey) =>
      tester.widget<TextField>(find.byKey(Key(fieldKey))).decoration?.errorText;

  group('Save availability', () {
    testWidgets('is disabled while the form is untouched', (tester) async {
      await pumpSheet(tester);

      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('stays disabled when only the term is filled in', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
      await tester.pump();

      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('stays disabled when only the translation is filled in', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(
        find.byKey(const Key('translation-field')),
        'das Buch',
      );
      await tester.pump();

      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('becomes enabled once both fields have content', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
      await tester.enterText(
        find.byKey(const Key('translation-field')),
        'das Buch',
      );
      await tester.pump();

      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('treats whitespace-only input as empty', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('term-field')), '   ');
      await tester.enterText(
        find.byKey(const Key('translation-field')),
        'das Buch',
      );
      await tester.pump();

      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('goes back to disabled when a field is cleared again', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
      await tester.enterText(
        find.byKey(const Key('translation-field')),
        'das Buch',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('term-field')), '');
      await tester.pump();

      expect(saveEnabled(tester), isFalse);
    });
  });

  group('inline feedback', () {
    testWidgets('says nothing before the user has visited a field', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(errorOn(tester, 'term-field'), isNull);
      expect(errorOn(tester, 'translation-field'), isNull);
    });

    testWidgets('flags the term once it is left behind still empty', (
      tester,
    ) async {
      await pumpSheet(tester);

      // The term field is autofocused; moving to the translation field leaves
      // it behind empty, which is the moment to say so.
      await tester.tap(find.byKey(const Key('translation-field')));
      await tester.pumpAndSettle();

      expect(errorOn(tester, 'term-field'), 'Required');
    });

    testWidgets('withdraws the term warning as soon as the term is filled', (
      tester,
    ) async {
      await pumpSheet(tester);
      await tester.tap(find.byKey(const Key('translation-field')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
      await tester.pump();

      expect(errorOn(tester, 'term-field'), isNull);
    });

    testWidgets('flags each field independently once both were visited', (
      tester,
    ) async {
      await pumpSheet(tester);

      // Focus moves term -> translation -> term, so both have been left empty.
      await tester.tap(find.byKey(const Key('translation-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('term-field')));
      await tester.pumpAndSettle();

      expect(errorOn(tester, 'term-field'), 'Required');
      expect(errorOn(tester, 'translation-field'), 'Required');
    });
  });

  testWidgets('reports the entered pair when saved', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byKey(const Key('term-field')), 'el libro');
    await tester.enterText(
      find.byKey(const Key('translation-field')),
      'das Buch',
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(submissions, [('el libro', 'das Buch')]);
  });
}
