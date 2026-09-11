import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockscreen_learning_app/ui/core/widgets/language_field.dart';

void main() {
  final picked = <String>[];

  setUp(picked.clear);

  Future<void> pumpField(WidgetTester tester, {String value = 'es'}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageField(
            label: 'Language you are learning',
            helperText: 'The terms in this deck are written in it',
            value: value,
            onSelected: picked.add,
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the language by name, not by the code it stores', (
    tester,
  ) async {
    await pumpField(tester);

    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('es'), findsNothing);
  });

  testWidgets('offers the catalogue when opened', (tester) async {
    await pumpField(tester);

    await openMenu(tester);

    expect(find.widgetWithText(MenuItemButton, 'French'), findsOneWidget);
    expect(find.widgetWithText(MenuItemButton, 'German'), findsOneWidget);
  });

  testWidgets('narrows the list to what was typed', (tester) async {
    await pumpField(tester);
    await openMenu(tester);

    await tester.enterText(find.byType(TextField), 'fren');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(MenuItemButton, 'French'), findsOneWidget);
    expect(find.widgetWithText(MenuItemButton, 'German'), findsNothing);
  });

  testWidgets('searches the code too, for someone who thinks in codes', (
    tester,
  ) async {
    await pumpField(tester);
    await openMenu(tester);

    await tester.enterText(find.byType(TextField), 'de');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(MenuItemButton, 'German'), findsOneWidget);
  });

  testWidgets('reports the code of the language searched for and picked', (
    tester,
  ) async {
    await pumpField(tester);
    await openMenu(tester);

    // Searched rather than scrolled to, because the menu opens scrolled to the
    // current selection and the catalogue is longer than one screen.
    await tester.enterText(find.byType(TextField), 'French');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'French'));
    await tester.pumpAndSettle();

    expect(picked, ['fr']);
  });

  testWidgets('leaves the value alone until something is actually picked', (
    tester,
  ) async {
    await pumpField(tester);
    await openMenu(tester);

    await tester.enterText(find.byType(TextField), 'fren');
    await tester.pumpAndSettle();

    expect(picked, isEmpty);
  });

  testWidgets(
    'keeps a code the catalogue does not know, so a deck saved when this '
    'was a free text field is not silently blanked',
    (tester) async {
      await pumpField(tester, value: 'elvish');

      expect(find.text('elvish'), findsOneWidget);

      await openMenu(tester);

      expect(find.widgetWithText(MenuItemButton, 'elvish'), findsOneWidget);
    },
  );
}
