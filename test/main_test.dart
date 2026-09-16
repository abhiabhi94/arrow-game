import 'package:arrow_game/l10n/app_localizations.dart';
import 'package:arrow_game/main.dart';
import 'package:arrow_game/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the language choice maps to a locale, or hands it back to the device', () {
    // Null is the point: MaterialApp then resolves the device locale against
    // supportedLocales, so a phone set to Hindi opens in Hindi.
    expect(localeFor(LanguageChoice.system), isNull);
    expect(localeFor(LanguageChoice.english), const Locale('en'));
    expect(localeFor(LanguageChoice.hindi), const Locale('hi'));
  });

  test('both languages are on offer', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(<String>['en', 'hi']),
    );
  });

  test('the theme choice maps to a theme mode', () {
    expect(themeModeFor(ThemeChoice.system), ThemeMode.system);
    expect(themeModeFor(ThemeChoice.light), ThemeMode.light);
    expect(themeModeFor(ThemeChoice.dark), ThemeMode.dark);
  });
}
