import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Swipe fast. Think faster.'**
  String get appTagline;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeStars.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} stars'**
  String homeStars(int count, int total);

  /// No description provided for @homeLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get homeLevels;

  /// No description provided for @homeLevelsHint.
  ///
  /// In en, this message translates to:
  /// **'Clear a level to unlock the next one. Three stars for a flawless run.'**
  String get homeLevelsHint;

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String levelNumber(int number);

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get levelLocked;

  /// No description provided for @levelName1.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get levelName1;

  /// No description provided for @levelName2.
  ///
  /// In en, this message translates to:
  /// **'Getting Going'**
  String get levelName2;

  /// No description provided for @levelName3.
  ///
  /// In en, this message translates to:
  /// **'Quick Hands'**
  String get levelName3;

  /// No description provided for @levelName4.
  ///
  /// In en, this message translates to:
  /// **'Mirror Mirror'**
  String get levelName4;

  /// No description provided for @levelName5.
  ///
  /// In en, this message translates to:
  /// **'Opposite Day'**
  String get levelName5;

  /// No description provided for @levelName6.
  ///
  /// In en, this message translates to:
  /// **'Double Take'**
  String get levelName6;

  /// No description provided for @levelName7.
  ///
  /// In en, this message translates to:
  /// **'Short Fuse'**
  String get levelName7;

  /// No description provided for @levelName8.
  ///
  /// In en, this message translates to:
  /// **'Tick Tock'**
  String get levelName8;

  /// No description provided for @levelName9.
  ///
  /// In en, this message translates to:
  /// **'Pressure Cooker'**
  String get levelName9;

  /// No description provided for @levelName10.
  ///
  /// In en, this message translates to:
  /// **'Now You See It'**
  String get levelName10;

  /// No description provided for @levelName11.
  ///
  /// In en, this message translates to:
  /// **'Ghost Town'**
  String get levelName11;

  /// No description provided for @levelName12.
  ///
  /// In en, this message translates to:
  /// **'Blink and Miss'**
  String get levelName12;

  /// No description provided for @levelName13.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Read Me'**
  String get levelName13;

  /// No description provided for @levelName14.
  ///
  /// In en, this message translates to:
  /// **'Word Salad'**
  String get levelName14;

  /// No description provided for @levelName15.
  ///
  /// In en, this message translates to:
  /// **'Mixed Signals'**
  String get levelName15;

  /// No description provided for @levelName16.
  ///
  /// In en, this message translates to:
  /// **'All Together Now'**
  String get levelName16;

  /// No description provided for @levelName17.
  ///
  /// In en, this message translates to:
  /// **'Full Tilt'**
  String get levelName17;

  /// No description provided for @levelName18.
  ///
  /// In en, this message translates to:
  /// **'Overdrive'**
  String get levelName18;

  /// No description provided for @levelName19.
  ///
  /// In en, this message translates to:
  /// **'Lightning Round'**
  String get levelName19;

  /// No description provided for @levelName20.
  ///
  /// In en, this message translates to:
  /// **'Grand Finale'**
  String get levelName20;

  /// No description provided for @introRules.
  ///
  /// In en, this message translates to:
  /// **'This level'**
  String get introRules;

  /// No description provided for @introTarget.
  ///
  /// In en, this message translates to:
  /// **'{count} arrows'**
  String introTarget(int count);

  /// No description provided for @introTime.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s on the clock'**
  String introTime(int seconds);

  /// No description provided for @introLives.
  ///
  /// In en, this message translates to:
  /// **'3 lives'**
  String get introLives;

  /// No description provided for @introGo.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get introGo;

  /// No description provided for @ruleNormal.
  ///
  /// In en, this message translates to:
  /// **'Swipe (or tap) the way the arrow points'**
  String get ruleNormal;

  /// No description provided for @ruleReverse.
  ///
  /// In en, this message translates to:
  /// **'Coral arrows: go the opposite way'**
  String get ruleReverse;

  /// No description provided for @ruleGhost.
  ///
  /// In en, this message translates to:
  /// **'Ghost arrows vanish — remember them'**
  String get ruleGhost;

  /// No description provided for @ruleDecoy.
  ///
  /// In en, this message translates to:
  /// **'Trust the arrow, not the word'**
  String get ruleDecoy;

  /// No description provided for @ruleFuse.
  ///
  /// In en, this message translates to:
  /// **'Each arrow has a fuse — answer before it burns out'**
  String get ruleFuse;

  /// No description provided for @directionUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get directionUp;

  /// No description provided for @directionRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get directionRight;

  /// No description provided for @directionDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get directionDown;

  /// No description provided for @directionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get directionLeft;

  /// No description provided for @gamePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gamePause;

  /// No description provided for @gameResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get gameResume;

  /// No description provided for @gamePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get gamePaused;

  /// No description provided for @gamePausedBody.
  ///
  /// In en, this message translates to:
  /// **'Take a breath. The clock is stopped.'**
  String get gamePausedBody;

  /// No description provided for @gameQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit level'**
  String get gameQuit;

  /// No description provided for @gameBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get gameBack;

  /// No description provided for @hudHits.
  ///
  /// In en, this message translates to:
  /// **'{hits}/{target}'**
  String hudHits(int hits, int target);

  /// No description provided for @hudLives.
  ///
  /// In en, this message translates to:
  /// **'{lives} lives left'**
  String hudLives(int lives);

  /// No description provided for @streakOnFire.
  ///
  /// In en, this message translates to:
  /// **'On fire!'**
  String get streakOnFire;

  /// No description provided for @streakUnstoppable.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable!'**
  String get streakUnstoppable;

  /// No description provided for @streakLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend!'**
  String get streakLegend;

  /// No description provided for @clearedTitle.
  ///
  /// In en, this message translates to:
  /// **'Level cleared!'**
  String get clearedTitle;

  /// No description provided for @clearedFlawless.
  ///
  /// In en, this message translates to:
  /// **'Flawless run — three stars!'**
  String get clearedFlawless;

  /// No description provided for @clearedGood.
  ///
  /// In en, this message translates to:
  /// **'Nice! One slip, two stars.'**
  String get clearedGood;

  /// No description provided for @clearedOkay.
  ///
  /// In en, this message translates to:
  /// **'Made it! Fewer slips next time for more stars.'**
  String get clearedOkay;

  /// No description provided for @clearedTime.
  ///
  /// In en, this message translates to:
  /// **'Time {time}'**
  String clearedTime(String time);

  /// No description provided for @clearedNewBest.
  ///
  /// In en, this message translates to:
  /// **'New best time!'**
  String get clearedNewBest;

  /// No description provided for @clearedNext.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get clearedNext;

  /// No description provided for @clearedReplay.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get clearedReplay;

  /// No description provided for @clearedHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get clearedHome;

  /// No description provided for @clearedAllDone.
  ///
  /// In en, this message translates to:
  /// **'You beat every level. Legend!'**
  String get clearedAllDone;

  /// No description provided for @outOfLivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of lives'**
  String get outOfLivesTitle;

  /// No description provided for @outOfLivesBody.
  ///
  /// In en, this message translates to:
  /// **'Three slips and the level resets. Shake it off and go again?'**
  String get outOfLivesBody;

  /// No description provided for @outOfLivesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get outOfLivesRetry;

  /// No description provided for @timeUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timeUpTitle;

  /// No description provided for @timeUpBody.
  ///
  /// In en, this message translates to:
  /// **'So close — {hits} of {target}. One more go?'**
  String timeUpBody(int hits, int target);

  /// No description provided for @timeUpRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get timeUpRetry;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A tick on every swipe, a buzz on a slip'**
  String get settingsVibrationSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get settingsHowToPlay;

  /// No description provided for @howToPlayBody.
  ///
  /// In en, this message translates to:
  /// **'An arrow pops up — swipe the arena or tap the pad in the direction it points. Coral arrows mean the opposite way, ghost arrows fade so you have to remember them, and some arrows wear a misleading word. Three lives per level, a clock on every level, and three stars for a flawless run.'**
  String get howToPlayBody;

  /// No description provided for @settingsResetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get settingsResetProgress;

  /// No description provided for @settingsResetProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock every level again and clear all stars'**
  String get settingsResetProgressSubtitle;

  /// No description provided for @settingsResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress?'**
  String get settingsResetConfirmTitle;

  /// No description provided for @settingsResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Stars and best times will be wiped. This can\'t be undone.'**
  String get settingsResetConfirmBody;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
