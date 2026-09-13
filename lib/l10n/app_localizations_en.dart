// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Arrow';

  @override
  String get appTagline => 'Slide every arrow out';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeNextUp => 'Next up';

  @override
  String get homePlay => 'Play';

  @override
  String get homeReplay => 'Replay';

  @override
  String get homeAllCleared => 'Every level cleared — legend!';

  @override
  String get homeJourney => 'Your journey';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardStart => 'Let\'s play!';

  @override
  String get onboardTitle1 => 'Tap an arrow';

  @override
  String get onboardBody1 => 'It slides out the way it points. Go on, tap it.';

  @override
  String get onboardDone1 => 'That\'s it — one down!';

  @override
  String get onboardTitle2 => 'Watch for blockers';

  @override
  String get onboardBody2 =>
      'An arrow can\'t pass through another. Tap the one pointing up and see it bump.';

  @override
  String get onboardBumped2 =>
      'Bumped! In a real level that costs a life. Clear the top one first, then the other.';

  @override
  String get onboardDone2 => 'Order matters — you\'ve got it.';

  @override
  String get onboardTitle3 => 'That\'s the whole game';

  @override
  String get onboardRuleLives => '3 lives per level — a bump costs one';

  @override
  String get onboardRuleClock =>
      'Beat the clock — plenty of time, but it ticks';

  @override
  String get onboardRuleHints =>
      'Stuck? 3 hints per level light up a free arrow';

  @override
  String get onboardRuleZoom => 'Big boards later — pinch or tap to zoom';

  @override
  String homeStars(int count, int total) {
    return '$count of $total stars';
  }

  @override
  String get homeLevels => 'Levels';

  @override
  String get homeLevelsHint =>
      'Clear a level to unlock the next one. Three stars for a flawless run.';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String levelShort(int number) {
    return 'Lv.$number';
  }

  @override
  String get levelLocked => 'Locked';

  @override
  String get levelName1 => 'First Steps';

  @override
  String get levelName2 => 'Two Ways Out';

  @override
  String get levelName3 => 'Tight Corners';

  @override
  String get levelName4 => 'Criss-cross';

  @override
  String get levelName5 => 'Bottleneck';

  @override
  String get levelName6 => 'Tangle';

  @override
  String get levelName7 => 'Knot';

  @override
  String get levelName8 => 'Snarl';

  @override
  String get levelName9 => 'Labyrinth';

  @override
  String get levelName10 => 'Gridlock';

  @override
  String get levelName11 => 'Cobweb';

  @override
  String get levelName12 => 'Thicket';

  @override
  String get levelName13 => 'Maze Runner';

  @override
  String get levelName14 => 'Cat\'s Cradle';

  @override
  String get levelName15 => 'Traffic Jam';

  @override
  String get levelName16 => 'Spaghetti';

  @override
  String get levelName17 => 'Rush Hour';

  @override
  String get levelName18 => 'Gordian Knot';

  @override
  String get levelName19 => 'Escape Artist';

  @override
  String get levelName20 => 'Grand Exit';

  @override
  String get tutorialTap => 'Tap an arrow to slide it out the way it points.';

  @override
  String get tutorialBlocked =>
      'An arrow in the way costs a life — find the free ones first.';

  @override
  String get gameLoading => 'Laying out the arrows…';

  @override
  String get gamePause => 'Pause';

  @override
  String get gameResume => 'Resume';

  @override
  String get gamePaused => 'Paused';

  @override
  String get gamePausedBody => 'Take a breath. The clock is stopped.';

  @override
  String get gameQuit => 'Quit level';

  @override
  String get gameRestart => 'Restart level';

  @override
  String get gameBack => 'Back';

  @override
  String hudArrows(int out, int total) {
    return '$out/$total';
  }

  @override
  String hudLives(int lives) {
    return '$lives lives left';
  }

  @override
  String get toolHint => 'Hint';

  @override
  String toolHintLeft(int count) {
    return '$count hints left';
  }

  @override
  String get toolHintNone => 'No hints left';

  @override
  String get toolGrid => 'Grid lines';

  @override
  String toolGridLocked(int level) {
    return 'Grid lines unlock after level $level';
  }

  @override
  String get toolZoomIn => 'Zoom in';

  @override
  String get toolZoomOut => 'Zoom out';

  @override
  String get gridUnlockedToast =>
      'Grid lines unlocked! Find the toggle under the board.';

  @override
  String get clearedTitle => 'Level cleared!';

  @override
  String get clearedFlawless => 'Flawless run — three stars!';

  @override
  String get clearedGood => 'Nice! One slip, two stars.';

  @override
  String get clearedOkay => 'Made it! Fewer slips next time for more stars.';

  @override
  String clearedTime(String time) {
    return 'Time $time';
  }

  @override
  String get clearedNewBest => 'New best time!';

  @override
  String get clearedNext => 'Next level';

  @override
  String get clearedReplay => 'Play again';

  @override
  String get clearedHome => 'Home';

  @override
  String get clearedAllDone => 'You beat every level. Legend!';

  @override
  String get outOfLivesTitle => 'Out of lives';

  @override
  String get outOfLivesBody =>
      'Three blocked arrows and the level resets. Shake it off and go again?';

  @override
  String get outOfLivesRetry => 'Retry';

  @override
  String get timeUpTitle => 'Time\'s up!';

  @override
  String timeUpBody(int out, int total) {
    return 'So close — $out of $total arrows out. One more go?';
  }

  @override
  String get timeUpRetry => 'Try again';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsMusicSubtitle => 'A calm loop while you play';

  @override
  String get settingsSfx => 'Sound effects';

  @override
  String get settingsSfxSubtitle => 'A zup as each arrow slides out';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsHapticsSubtitle =>
      'A tick on every slide, a buzz on a bump';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsHowToPlay => 'How to play';

  @override
  String get howToPlayBody => 'Replay the two-minute walkthrough';

  @override
  String get settingsCredits => 'Music credits';

  @override
  String get creditsTitle => 'Credits';

  @override
  String get creditsIntro =>
      'The background music is released under a Creative Commons licence that asks for credit — here it is, gladly.';

  @override
  String creditsBy(String artist) {
    return 'by $artist';
  }

  @override
  String get settingsResetProgress => 'Reset progress';

  @override
  String get settingsResetProgressSubtitle =>
      'Lock every level again and clear all stars';

  @override
  String get settingsResetConfirmTitle => 'Reset all progress?';

  @override
  String get settingsResetConfirmBody =>
      'Stars and best times will be wiped. This can\'t be undone.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonReset => 'Reset';
}
