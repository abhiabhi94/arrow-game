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
  String get appTagline => 'Swipe fast. Think faster.';

  @override
  String get homeSettings => 'Settings';

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
  String get levelLocked => 'Locked';

  @override
  String get levelName1 => 'Warm-up';

  @override
  String get levelName2 => 'Getting Going';

  @override
  String get levelName3 => 'Quick Hands';

  @override
  String get levelName4 => 'Mirror Mirror';

  @override
  String get levelName5 => 'Opposite Day';

  @override
  String get levelName6 => 'Double Take';

  @override
  String get levelName7 => 'Short Fuse';

  @override
  String get levelName8 => 'Tick Tock';

  @override
  String get levelName9 => 'Pressure Cooker';

  @override
  String get levelName10 => 'Now You See It';

  @override
  String get levelName11 => 'Ghost Town';

  @override
  String get levelName12 => 'Blink and Miss';

  @override
  String get levelName13 => 'Don\'t Read Me';

  @override
  String get levelName14 => 'Word Salad';

  @override
  String get levelName15 => 'Mixed Signals';

  @override
  String get levelName16 => 'All Together Now';

  @override
  String get levelName17 => 'Full Tilt';

  @override
  String get levelName18 => 'Overdrive';

  @override
  String get levelName19 => 'Lightning Round';

  @override
  String get levelName20 => 'Grand Finale';

  @override
  String get introRules => 'This level';

  @override
  String introTarget(int count) {
    return '$count arrows';
  }

  @override
  String introTime(int seconds) {
    return '${seconds}s on the clock';
  }

  @override
  String get introLives => '3 lives';

  @override
  String get introGo => 'Go!';

  @override
  String get ruleNormal => 'Swipe (or tap) the way the arrow points';

  @override
  String get ruleReverse => 'Coral arrows: go the opposite way';

  @override
  String get ruleGhost => 'Ghost arrows vanish — remember them';

  @override
  String get ruleDecoy => 'Trust the arrow, not the word';

  @override
  String get ruleFuse => 'Each arrow has a fuse — answer before it burns out';

  @override
  String get directionUp => 'Up';

  @override
  String get directionRight => 'Right';

  @override
  String get directionDown => 'Down';

  @override
  String get directionLeft => 'Left';

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
  String get gameBack => 'Back';

  @override
  String hudHits(int hits, int target) {
    return '$hits/$target';
  }

  @override
  String hudLives(int lives) {
    return '$lives lives left';
  }

  @override
  String get streakOnFire => 'On fire!';

  @override
  String get streakUnstoppable => 'Unstoppable!';

  @override
  String get streakLegend => 'Legend!';

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
      'Three slips and the level resets. Shake it off and go again?';

  @override
  String get outOfLivesRetry => 'Retry';

  @override
  String get timeUpTitle => 'Time\'s up!';

  @override
  String timeUpBody(int hits, int target) {
    return 'So close — $hits of $target. One more go?';
  }

  @override
  String get timeUpRetry => 'Try again';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationSubtitle =>
      'A tick on every swipe, a buzz on a slip';

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
  String get howToPlayBody =>
      'An arrow pops up — swipe the arena or tap the pad in the direction it points. Coral arrows mean the opposite way, ghost arrows fade so you have to remember them, and some arrows wear a misleading word. Three lives per level, a clock on every level, and three stars for a flawless run.';

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
