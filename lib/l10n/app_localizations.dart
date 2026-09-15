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
  /// **'Slide every arrow out'**
  String get appTagline;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get homeNextUp;

  /// No description provided for @homePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get homePlay;

  /// No description provided for @homeReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get homeReplay;

  /// No description provided for @homeAllCleared.
  ///
  /// In en, this message translates to:
  /// **'Every level cleared — legend!'**
  String get homeAllCleared;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homeResumeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get homeResumeEyebrow;

  /// No description provided for @homeResumeProgress.
  ///
  /// In en, this message translates to:
  /// **'{out} of {total} arrows out · {time} on the clock'**
  String homeResumeProgress(int out, int total, String time);

  /// No description provided for @homeJourney.
  ///
  /// In en, this message translates to:
  /// **'Your journey'**
  String get homeJourney;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @onboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// No description provided for @onboardStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play!'**
  String get onboardStart;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow'**
  String get onboardTitle1;

  /// No description provided for @onboardBody1.
  ///
  /// In en, this message translates to:
  /// **'It slides out the way it points. Go on, tap it.'**
  String get onboardBody1;

  /// No description provided for @onboardDone1.
  ///
  /// In en, this message translates to:
  /// **'That\'s it — one down!'**
  String get onboardDone1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Watch for blockers'**
  String get onboardTitle2;

  /// No description provided for @onboardBody2.
  ///
  /// In en, this message translates to:
  /// **'An arrow can\'t pass through another. Tap the one pointing up and see it bump.'**
  String get onboardBody2;

  /// No description provided for @onboardBumped2.
  ///
  /// In en, this message translates to:
  /// **'Bumped! In a real level that costs a life. Clear the top one first, then the other.'**
  String get onboardBumped2;

  /// No description provided for @onboardDone2.
  ///
  /// In en, this message translates to:
  /// **'Order matters — you\'ve got it.'**
  String get onboardDone2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'That\'s the whole game'**
  String get onboardTitle3;

  /// No description provided for @onboardRuleLives.
  ///
  /// In en, this message translates to:
  /// **'3 lives per level — a bump costs a life'**
  String get onboardRuleLives;

  /// No description provided for @onboardRuleClock.
  ///
  /// In en, this message translates to:
  /// **'Beat the clock — plenty of time, but it ticks'**
  String get onboardRuleClock;

  /// No description provided for @onboardRuleHints.
  ///
  /// In en, this message translates to:
  /// **'Stuck? 3 hints per level light up a free arrow'**
  String get onboardRuleHints;

  /// No description provided for @onboardRuleZoom.
  ///
  /// In en, this message translates to:
  /// **'Big boards later — pinch or tap to zoom'**
  String get onboardRuleZoom;

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

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv.{number}'**
  String levelShort(int number);

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get levelLocked;

  /// No description provided for @levelName1.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get levelName1;

  /// No description provided for @levelName2.
  ///
  /// In en, this message translates to:
  /// **'Two Ways Out'**
  String get levelName2;

  /// No description provided for @levelName3.
  ///
  /// In en, this message translates to:
  /// **'Tight Corners'**
  String get levelName3;

  /// No description provided for @levelName4.
  ///
  /// In en, this message translates to:
  /// **'Criss-cross'**
  String get levelName4;

  /// No description provided for @levelName5.
  ///
  /// In en, this message translates to:
  /// **'Bottleneck'**
  String get levelName5;

  /// No description provided for @levelName6.
  ///
  /// In en, this message translates to:
  /// **'Tangle'**
  String get levelName6;

  /// No description provided for @levelName7.
  ///
  /// In en, this message translates to:
  /// **'Knot'**
  String get levelName7;

  /// No description provided for @levelName8.
  ///
  /// In en, this message translates to:
  /// **'Snarl'**
  String get levelName8;

  /// No description provided for @levelName9.
  ///
  /// In en, this message translates to:
  /// **'Labyrinth'**
  String get levelName9;

  /// No description provided for @levelName10.
  ///
  /// In en, this message translates to:
  /// **'Gridlock'**
  String get levelName10;

  /// No description provided for @levelName11.
  ///
  /// In en, this message translates to:
  /// **'Cobweb'**
  String get levelName11;

  /// No description provided for @levelName12.
  ///
  /// In en, this message translates to:
  /// **'Thicket'**
  String get levelName12;

  /// No description provided for @levelName13.
  ///
  /// In en, this message translates to:
  /// **'Maze Runner'**
  String get levelName13;

  /// No description provided for @levelName14.
  ///
  /// In en, this message translates to:
  /// **'Cat\'s Cradle'**
  String get levelName14;

  /// No description provided for @levelName15.
  ///
  /// In en, this message translates to:
  /// **'Traffic Jam'**
  String get levelName15;

  /// No description provided for @levelName16.
  ///
  /// In en, this message translates to:
  /// **'Spaghetti'**
  String get levelName16;

  /// No description provided for @levelName17.
  ///
  /// In en, this message translates to:
  /// **'Rush Hour'**
  String get levelName17;

  /// No description provided for @levelName18.
  ///
  /// In en, this message translates to:
  /// **'Gordian Knot'**
  String get levelName18;

  /// No description provided for @levelName19.
  ///
  /// In en, this message translates to:
  /// **'Escape Artist'**
  String get levelName19;

  /// No description provided for @levelName20.
  ///
  /// In en, this message translates to:
  /// **'Deep End'**
  String get levelName20;

  /// No description provided for @levelName21.
  ///
  /// In en, this message translates to:
  /// **'Undertow'**
  String get levelName21;

  /// No description provided for @levelName22.
  ///
  /// In en, this message translates to:
  /// **'Hedge Maze'**
  String get levelName22;

  /// No description provided for @levelName23.
  ///
  /// In en, this message translates to:
  /// **'Ball of Yarn'**
  String get levelName23;

  /// No description provided for @levelName24.
  ///
  /// In en, this message translates to:
  /// **'Crossfire'**
  String get levelName24;

  /// No description provided for @levelName25.
  ///
  /// In en, this message translates to:
  /// **'Switchyard'**
  String get levelName25;

  /// No description provided for @levelName26.
  ///
  /// In en, this message translates to:
  /// **'Snake Pit'**
  String get levelName26;

  /// No description provided for @levelName27.
  ///
  /// In en, this message translates to:
  /// **'Hairball'**
  String get levelName27;

  /// No description provided for @levelName28.
  ///
  /// In en, this message translates to:
  /// **'Clockwork'**
  String get levelName28;

  /// No description provided for @levelName29.
  ///
  /// In en, this message translates to:
  /// **'Whirlpool'**
  String get levelName29;

  /// No description provided for @levelName30.
  ///
  /// In en, this message translates to:
  /// **'Halfway Out'**
  String get levelName30;

  /// No description provided for @levelName31.
  ///
  /// In en, this message translates to:
  /// **'Circuit Board'**
  String get levelName31;

  /// No description provided for @levelName32.
  ///
  /// In en, this message translates to:
  /// **'Briar Patch'**
  String get levelName32;

  /// No description provided for @levelName33.
  ///
  /// In en, this message translates to:
  /// **'Root System'**
  String get levelName33;

  /// No description provided for @levelName34.
  ///
  /// In en, this message translates to:
  /// **'Tapestry'**
  String get levelName34;

  /// No description provided for @levelName35.
  ///
  /// In en, this message translates to:
  /// **'Hornet\'s Nest'**
  String get levelName35;

  /// No description provided for @levelName36.
  ///
  /// In en, this message translates to:
  /// **'Deep Weave'**
  String get levelName36;

  /// No description provided for @levelName37.
  ///
  /// In en, this message translates to:
  /// **'Eye of the Needle'**
  String get levelName37;

  /// No description provided for @levelName38.
  ///
  /// In en, this message translates to:
  /// **'Pandemonium'**
  String get levelName38;

  /// No description provided for @levelName39.
  ///
  /// In en, this message translates to:
  /// **'Point of No Return'**
  String get levelName39;

  /// No description provided for @levelName40.
  ///
  /// In en, this message translates to:
  /// **'The Gauntlet'**
  String get levelName40;

  /// No description provided for @levelName41.
  ///
  /// In en, this message translates to:
  /// **'Overgrowth'**
  String get levelName41;

  /// No description provided for @levelName42.
  ///
  /// In en, this message translates to:
  /// **'Chain Reaction'**
  String get levelName42;

  /// No description provided for @levelName43.
  ///
  /// In en, this message translates to:
  /// **'Logjam'**
  String get levelName43;

  /// No description provided for @levelName44.
  ///
  /// In en, this message translates to:
  /// **'Bramble'**
  String get levelName44;

  /// No description provided for @levelName45.
  ///
  /// In en, this message translates to:
  /// **'Crosshatch'**
  String get levelName45;

  /// No description provided for @levelName46.
  ///
  /// In en, this message translates to:
  /// **'Nested Dolls'**
  String get levelName46;

  /// No description provided for @levelName47.
  ///
  /// In en, this message translates to:
  /// **'Deadlock'**
  String get levelName47;

  /// No description provided for @levelName48.
  ///
  /// In en, this message translates to:
  /// **'Iron Maze'**
  String get levelName48;

  /// No description provided for @levelName49.
  ///
  /// In en, this message translates to:
  /// **'Loose Threads'**
  String get levelName49;

  /// No description provided for @levelName50.
  ///
  /// In en, this message translates to:
  /// **'Dead Reckoning'**
  String get levelName50;

  /// No description provided for @levelName51.
  ///
  /// In en, this message translates to:
  /// **'Fever Dream'**
  String get levelName51;

  /// No description provided for @levelName52.
  ///
  /// In en, this message translates to:
  /// **'Cross Purposes'**
  String get levelName52;

  /// No description provided for @levelName53.
  ///
  /// In en, this message translates to:
  /// **'Ant Farm'**
  String get levelName53;

  /// No description provided for @levelName54.
  ///
  /// In en, this message translates to:
  /// **'Ravel'**
  String get levelName54;

  /// No description provided for @levelName55.
  ///
  /// In en, this message translates to:
  /// **'Last Resort'**
  String get levelName55;

  /// No description provided for @levelName56.
  ///
  /// In en, this message translates to:
  /// **'Vanishing Point'**
  String get levelName56;

  /// No description provided for @levelName57.
  ///
  /// In en, this message translates to:
  /// **'Endgame'**
  String get levelName57;

  /// No description provided for @levelName58.
  ///
  /// In en, this message translates to:
  /// **'The Long Haul'**
  String get levelName58;

  /// No description provided for @levelName59.
  ///
  /// In en, this message translates to:
  /// **'Final Approach'**
  String get levelName59;

  /// No description provided for @levelName60.
  ///
  /// In en, this message translates to:
  /// **'Grand Exit'**
  String get levelName60;

  /// No description provided for @tutorialTap.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow to slide it out the way it points.'**
  String get tutorialTap;

  /// No description provided for @tutorialBlocked.
  ///
  /// In en, this message translates to:
  /// **'An arrow in the way costs a life — find the free ones first.'**
  String get tutorialBlocked;

  /// No description provided for @gameLoading.
  ///
  /// In en, this message translates to:
  /// **'Laying out the arrows…'**
  String get gameLoading;

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

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get resumeTitle;

  /// No description provided for @resumeBody.
  ///
  /// In en, this message translates to:
  /// **'You left this level with {out} of {total} arrows out and {time} on the clock.'**
  String resumeBody(int out, int total, String time);

  /// No description provided for @resumeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get resumeContinue;

  /// No description provided for @resumeStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get resumeStartOver;

  /// No description provided for @gameRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart level'**
  String get gameRestart;

  /// No description provided for @gameBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get gameBack;

  /// No description provided for @hudArrows.
  ///
  /// In en, this message translates to:
  /// **'{out}/{total}'**
  String hudArrows(int out, int total);

  /// No description provided for @hudLives.
  ///
  /// In en, this message translates to:
  /// **'{lives} lives left'**
  String hudLives(int lives);

  /// No description provided for @toolHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get toolHint;

  /// No description provided for @toolHintLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} hints left'**
  String toolHintLeft(int count);

  /// No description provided for @toolHintNone.
  ///
  /// In en, this message translates to:
  /// **'No hints left'**
  String get toolHintNone;

  /// No description provided for @toolGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid lines'**
  String get toolGrid;

  /// No description provided for @toolGridLocked.
  ///
  /// In en, this message translates to:
  /// **'Grid lines unlock after level {level}'**
  String toolGridLocked(int level);

  /// No description provided for @toolZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get toolZoomIn;

  /// No description provided for @toolZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get toolZoomOut;

  /// No description provided for @gridUnlockedToast.
  ///
  /// In en, this message translates to:
  /// **'Grid lines unlocked! Find the toggle under the board.'**
  String get gridUnlockedToast;

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
  /// **'That was the last one. Carry on and finish for a single star, or restart the level?'**
  String get outOfLivesBody;

  /// No description provided for @outOfLivesKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get outOfLivesKeepGoing;

  /// No description provided for @outOfLivesRetry.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get outOfLivesRetry;

  /// No description provided for @timeUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timeUpTitle;

  /// No description provided for @timeUpBody.
  ///
  /// In en, this message translates to:
  /// **'So close — {out} of {total} arrows out. One more go?'**
  String timeUpBody(int out, int total);

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

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// No description provided for @settingsMusicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A calm loop while you play'**
  String get settingsMusicSubtitle;

  /// No description provided for @settingsSfx.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSfx;

  /// No description provided for @settingsSfxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The little sounds as you play'**
  String get settingsSfxSubtitle;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A tick on every slide, a buzz on a bump'**
  String get settingsHapticsSubtitle;

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
  /// **'Replay the two-minute walkthrough'**
  String get howToPlayBody;

  /// No description provided for @settingsCredits.
  ///
  /// In en, this message translates to:
  /// **'Music credits'**
  String get settingsCredits;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsBy.
  ///
  /// In en, this message translates to:
  /// **'by {artist}'**
  String creditsBy(String artist);

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
