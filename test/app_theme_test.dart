import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagara/main.dart';

void main() {
  for (final brightness in Brightness.values) {
    group('$brightness theme', () {
      final theme = LockscreenLearningApp.themeFor(brightness);

      test('sets the header apart from the page body', () {
        // The whole point of the app bar theme: Material 3 would otherwise
        // paint the header the same colour as the content behind it.
        expect(
          theme.appBarTheme.backgroundColor,
          isNot(theme.colorScheme.surface),
        );
      });

      test('draws the header colour from the seeded scheme', () {
        expect(
          theme.appBarTheme.backgroundColor,
          theme.colorScheme.surfaceContainer,
        );
      });

      test('separates the header with a hairline rather than a shadow', () {
        expect(theme.appBarTheme.shape, isA<Border>());
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
      });

      test('keeps the header title readable against it', () {
        expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onSurface);
      });
    });
  }
}
