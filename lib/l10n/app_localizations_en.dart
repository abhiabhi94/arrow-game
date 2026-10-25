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
  String get homeContinue => 'Continue';

  @override
  String get homeResumeEyebrow => 'Pick up where you left off';

  @override
  String homeResumeProgress(int out, int total, String time) {
    return '$out of $total arrows out · $time on the clock';
  }

  @override
  String get homeJourney => 'Your journey';

  @override
  String get chapterName1 => 'Lines';

  @override
  String get chapterName2 => 'Mirrors';

  @override
  String get chapterName3 => 'Locks';

  @override
  String get chapterName4 => 'Fog';

  @override
  String get chapterName5 => 'Pairs';

  @override
  String chapterHeading(int number, String name) {
    return 'Chapter $number · $name';
  }

  @override
  String chapterLevels(int first, int last) {
    return 'Levels $first–$last';
  }

  @override
  String get chapterBlurb1 =>
      'One rule: tap an arrow with a clear path and it slides out.';

  @override
  String get chapterBlurb2 =>
      'Mirrors on the board. An arrow bounces off and goes on.';

  @override
  String get chapterBlurb3 => 'Locked arrows wait for their key.';

  @override
  String get chapterBlurb4 => 'Some heads are hidden until a neighbour leaves.';

  @override
  String get chapterBlurb5 => 'Tethered arrows leave together.';

  @override
  String get introTitleMirrors => 'Mirrors';

  @override
  String get introBodyMirrors => 'Arrows bounce off mirrors.';

  @override
  String get introTitleLocks => 'Locks';

  @override
  String get introBodyLocks => 'The key goes first. Then the lock opens.';

  @override
  String get introTitleFog => 'Hidden heads';

  @override
  String get introBodyFog => 'Clear an arrow beside it to see where it points.';

  @override
  String get introTitlePairs => 'Pairs';

  @override
  String get introBodyPairs => 'One tap, both go. Both paths must be clear.';

  @override
  String get introGotIt => 'Got it';

  @override
  String get tutorialMirrors => 'Arrows bounce off mirrors.';

  @override
  String get tutorialLocks => 'A locked arrow waits for its key.';

  @override
  String get tutorialFog =>
      'Clear an arrow beside a dashed one to see its head. Tapping a dashed one is free.';

  @override
  String get tutorialPairs => 'Tethered arrows leave together.';

  @override
  String get dailyEyebrow => 'Daily board';

  @override
  String get dailyTitle => 'Today\'s board';

  @override
  String dailyBody(int minutes, int arrows, String chapter) {
    return '$minutes minutes, $arrows arrows, $chapter rules. A fresh deal every day — yours alone.';
  }

  @override
  String dailyStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days day streak',
      one: '1 day streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String dailyBestToday(String time) {
    return 'Best today $time';
  }

  @override
  String get dailyClearedToday => 'Cleared today';

  @override
  String dailyNextInHours(int hours, int minutes) {
    return 'Next board in ${hours}h ${minutes}m';
  }

  @override
  String dailyNextInMinutes(int minutes) {
    return 'Next board in ${minutes}m';
  }

  @override
  String get dailyPlay => 'Play today';

  @override
  String get dailyReplay => 'Play it again';

  @override
  String get dailyLevelTitle => 'Daily board';

  @override
  String get dailyClearedBody =>
      'Today\'s board is done. Come back tomorrow for a new one.';

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
  String get onboardRuleLives => '3 lives per level — a bump costs a life';

  @override
  String get onboardRuleClock =>
      'Beat the clock — plenty of time, but it ticks';

  @override
  String get onboardRuleHints =>
      'Stuck? 3 hints per level light up a free arrow';

  @override
  String get onboardRuleZoom => 'Big boards later — pinch or tap to zoom';

  @override
  String get onboardRuleRiddle => 'Lives all gone? Crack a riddle and carry on';

  @override
  String homeStars(int count, int total) {
    return '$count of $total stars';
  }

  @override
  String homeLevelsCleared(int cleared, int total) {
    return '$cleared of $total cleared';
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
  String get levelName20 => 'Deep End';

  @override
  String get levelName21 => 'Undertow';

  @override
  String get levelName22 => 'Hedge Maze';

  @override
  String get levelName23 => 'Ball of Yarn';

  @override
  String get levelName24 => 'Crossfire';

  @override
  String get levelName25 => 'Switchyard';

  @override
  String get levelName26 => 'Snake Pit';

  @override
  String get levelName27 => 'Hairball';

  @override
  String get levelName28 => 'Clockwork';

  @override
  String get levelName29 => 'Whirlpool';

  @override
  String get levelName30 => 'The Gauntlet';

  @override
  String get levelName31 => 'Circuit Board';

  @override
  String get levelName32 => 'Briar Patch';

  @override
  String get levelName33 => 'Root System';

  @override
  String get levelName34 => 'Tapestry';

  @override
  String get levelName35 => 'Hornet\'s Nest';

  @override
  String get levelName36 => 'Deep Weave';

  @override
  String get levelName37 => 'Eye of the Needle';

  @override
  String get levelName38 => 'Pandemonium';

  @override
  String get levelName39 => 'Point of No Return';

  @override
  String get levelName40 => 'Halfway Out';

  @override
  String get levelName41 => 'Overgrowth';

  @override
  String get levelName42 => 'Chain Reaction';

  @override
  String get levelName43 => 'Logjam';

  @override
  String get levelName44 => 'Bramble';

  @override
  String get levelName45 => 'Crosshatch';

  @override
  String get levelName46 => 'Nested Dolls';

  @override
  String get levelName47 => 'Deadlock';

  @override
  String get levelName48 => 'Iron Maze';

  @override
  String get levelName49 => 'Loose Threads';

  @override
  String get levelName50 => 'Dead Reckoning';

  @override
  String get levelName51 => 'Fever Dream';

  @override
  String get levelName52 => 'Cross Purposes';

  @override
  String get levelName53 => 'Ant Farm';

  @override
  String get levelName54 => 'Ravel';

  @override
  String get levelName55 => 'Last Resort';

  @override
  String get levelName56 => 'Vanishing Point';

  @override
  String get levelName57 => 'Tightrope';

  @override
  String get levelName58 => 'The Long Haul';

  @override
  String get levelName59 => 'Steep Climb';

  @override
  String get levelName60 => 'Turning Point';

  @override
  String get levelName61 => 'Second Wind';

  @override
  String get levelName62 => 'Uncharted';

  @override
  String get levelName63 => 'Wire Nest';

  @override
  String get levelName64 => 'Riptide';

  @override
  String get levelName65 => 'Wildwood';

  @override
  String get levelName66 => 'Ironclad';

  @override
  String get levelName67 => 'Catacombs';

  @override
  String get levelName68 => 'Tangled Web';

  @override
  String get levelName69 => 'Crush Depth';

  @override
  String get levelName70 => 'No Way Out';

  @override
  String get levelName71 => 'Thunderhead';

  @override
  String get levelName72 => 'Knot of Knots';

  @override
  String get levelName73 => 'The Crucible';

  @override
  String get levelName74 => 'Blackout';

  @override
  String get levelName75 => 'Vertigo';

  @override
  String get levelName76 => 'Razor\'s Edge';

  @override
  String get levelName77 => 'Event Horizon';

  @override
  String get levelName78 => 'The Abyss';

  @override
  String get levelName79 => 'Last Light';

  @override
  String get levelName80 => 'Beyond the Edge';

  @override
  String get levelName81 => 'Far Side';

  @override
  String get levelName82 => 'Maelstrom';

  @override
  String get levelName83 => 'Thornwall';

  @override
  String get levelName84 => 'Hall of Mirrors';

  @override
  String get levelName85 => 'Spiral Stair';

  @override
  String get levelName86 => 'Quicksand';

  @override
  String get levelName87 => 'Hydra';

  @override
  String get levelName88 => 'Frostbite';

  @override
  String get levelName89 => 'Storm Front';

  @override
  String get levelName90 => 'Iron Curtain';

  @override
  String get levelName91 => 'Long Night';

  @override
  String get levelName92 => 'Shatterpoint';

  @override
  String get levelName93 => 'Eye of the Storm';

  @override
  String get levelName94 => 'Deep Freeze';

  @override
  String get levelName95 => 'Dragon\'s Coil';

  @override
  String get levelName96 => 'Summit Fever';

  @override
  String get levelName97 => 'Starfall';

  @override
  String get levelName98 => 'Endless Maze';

  @override
  String get levelName99 => 'Almost Out';

  @override
  String get levelName100 => 'The Last Arrow';

  @override
  String get levelName101 => 'First Corner';

  @override
  String get levelName102 => 'Six Sides';

  @override
  String get levelName103 => 'Corner Turn';

  @override
  String get levelName104 => 'Square One';

  @override
  String get levelName105 => 'Building Blocks';

  @override
  String get levelName106 => 'Face Value';

  @override
  String get levelName107 => 'Edge of the Box';

  @override
  String get levelName108 => 'Corner Shop';

  @override
  String get levelName109 => 'Cube Root';

  @override
  String get levelName110 => 'Flat Pack';

  @override
  String get levelName111 => 'Hall of Glass';

  @override
  String get levelName112 => 'Prism';

  @override
  String get levelName113 => 'Reflex Angle';

  @override
  String get levelName114 => 'Looking Glass';

  @override
  String get levelName115 => 'Angle of Attack';

  @override
  String get levelName116 => 'Kaleidoscope';

  @override
  String get levelName117 => 'Glass Box';

  @override
  String get levelName118 => 'Bent Light';

  @override
  String get levelName119 => 'Mirror Image';

  @override
  String get levelName120 => 'Through the Looking Box';

  @override
  String get levelName121 => 'Locked Box';

  @override
  String get levelName122 => 'Combination';

  @override
  String get levelName123 => 'Strongbox';

  @override
  String get levelName124 => 'Key Ring';

  @override
  String get levelName125 => 'Treasure Chest';

  @override
  String get levelName126 => 'Puzzle Box';

  @override
  String get levelName127 => 'Vault';

  @override
  String get levelName128 => 'Safe Cracker';

  @override
  String get levelName129 => 'Skeleton Key';

  @override
  String get levelName130 => 'Lock, Stock';

  @override
  String get levelName131 => 'Black Box';

  @override
  String get levelName132 => 'Smoke and Mirrors';

  @override
  String get levelName133 => 'Fog Bank';

  @override
  String get levelName134 => 'Dark Side';

  @override
  String get levelName135 => 'Blind Corner';

  @override
  String get levelName136 => 'Shadow Box';

  @override
  String get levelName137 => 'Night Shift';

  @override
  String get levelName138 => 'Hidden Depths';

  @override
  String get levelName139 => 'Mist Cube';

  @override
  String get levelName140 => 'Eclipse';

  @override
  String get levelName141 => 'Two of a Kind';

  @override
  String get levelName142 => 'Tied Together';

  @override
  String get levelName143 => 'Double Act';

  @override
  String get levelName144 => 'Twin Peaks';

  @override
  String get levelName145 => 'Knotted';

  @override
  String get levelName146 => 'Partners';

  @override
  String get levelName147 => 'Lockstep';

  @override
  String get levelName148 => 'Side by Side';

  @override
  String get levelName149 => 'Full House';

  @override
  String get levelName150 => 'The Last Block';

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
  String get resumeTitle => 'Welcome back';

  @override
  String resumeBody(int out, int total, String time) {
    return 'You left this level with $out of $total arrows out and $time on the clock.';
  }

  @override
  String get resumeContinue => 'Continue';

  @override
  String get resumeStartOver => 'Start over';

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
    String _temp0 = intl.Intl.pluralLogic(
      lives,
      locale: localeName,
      other: '$lives lives left',
      one: '1 life left',
    );
    return '$_temp0';
  }

  @override
  String get toolHint => 'Hint';

  @override
  String toolHintLeft(int count) {
    return '$count hints left';
  }

  @override
  String get toolHintRiddle => 'Solve a riddle for one';

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
      'That was the last one. Crack a riddle and you can carry on from right here for a single star — or start the level over?';

  @override
  String get outOfLivesSolveRiddle => 'Solve a riddle';

  @override
  String get outOfLivesRetry => 'Start over';

  @override
  String get riddleTitle => 'Riddle me this';

  @override
  String get riddleIntro =>
      'Answer it and you are back on the board with one more life.';

  @override
  String get riddleIntroHint => 'Answer it and an arrow that can go lights up.';

  @override
  String get riddleField => 'Your answer';

  @override
  String get riddleSubmit => 'That\'s my answer';

  @override
  String get riddleHintAction => 'Give me a hint';

  @override
  String get riddleHintMore => 'One more nudge';

  @override
  String riddleFirstLetter(String letter) {
    return 'It starts with “$letter”';
  }

  @override
  String riddleLetters(int count) {
    return '$count letters';
  }

  @override
  String riddleWords(int count) {
    return '$count words';
  }

  @override
  String get riddleWrong1 => 'Nope. Not even close enough for “close enough”.';

  @override
  String get riddleWrong2 => 'Still no. The riddle is unmoved.';

  @override
  String get riddleWrong3 => 'Bold. Confident. Wrong — but very confident.';

  @override
  String get riddleWrong4 =>
      'We could do this all day. The riddle certainly can.';

  @override
  String get riddleWrong5 =>
      'The arrows have stopped watching. Probably for the best.';

  @override
  String get riddleWrong6 => 'That is a word, yes. Not the word, but a word.';

  @override
  String get riddleWrong7 => 'Interesting theory. Wrong, but interesting.';

  @override
  String get riddleWrong8 => 'The riddle heard you, and then unheard you.';

  @override
  String get riddleWrong9 => 'Not it — but points for commitment.';

  @override
  String get riddleWrong10 => 'Somewhere, a dictionary just flinched.';

  @override
  String get riddleWrong11 => 'So close! (It was not close.)';

  @override
  String get riddleWrong12 => 'Your answer and the right one have never met.';

  @override
  String get riddleWrong13 => 'No. The riddle is taking notes.';

  @override
  String get riddleWrong14 => 'A confident no from the judges.';

  @override
  String get riddleWrong15 => 'Wrong, but delivered with real authority.';

  @override
  String get riddleWrong16 => 'That is one of the words of all time.';

  @override
  String get riddleWrong17 => 'No. But keep that energy.';

  @override
  String get riddleWrong18 => 'The riddle has asked for a moment alone.';

  @override
  String get riddleWrong19 => 'Not near, not far — just comprehensively wrong.';

  @override
  String get riddleWrong20 => 'Declined. Politely, but firmly.';

  @override
  String get riddleWrong21 => 'Excellent spelling. Wrong word.';

  @override
  String get riddleWrong22 =>
      'You may be answering a different riddle entirely.';

  @override
  String get riddleWrong23 => 'The riddle suspects you are guessing now.';

  @override
  String get riddleWrong24 => 'No. And the riddle rather enjoyed that one.';

  @override
  String get riddleWrong25 => 'Try the one your first instinct said.';

  @override
  String get riddleWrong26 => 'Swing and a miss. Lovely form, though.';

  @override
  String get riddleWrong27 =>
      'That is a no from the riddle, and the riddle is in charge here.';

  @override
  String get riddleWrong28 => 'The riddle is smiling. That is not a good sign.';

  @override
  String get riddleWrong29 => 'Wrong — but wholeheartedly wrong.';

  @override
  String get riddleWrong30 =>
      'Not this time. Maybe the next one. Or the one after.';

  @override
  String get riddleCloseTitle => 'Close enough!';

  @override
  String riddleClose(String answer) {
    return 'Not quite the word we had — it was $answer — but near enough. One more life is yours.';
  }

  @override
  String riddleCloseHint(String answer) {
    return 'Not quite the word we had — it was $answer — but near enough. Your hint is on the board.';
  }

  @override
  String get riddleCorrect => 'Spot on!';

  @override
  String riddleCorrectBody(String answer) {
    return 'The answer was $answer. One more life, and the board is where you left it.';
  }

  @override
  String riddleCorrectBodyHint(String answer) {
    return 'The answer was $answer. An arrow that can go is lit up on the board.';
  }

  @override
  String get riddleBackToBoard => 'Back to the arrows';

  @override
  String get riddleSwap => 'Try a different riddle';

  @override
  String get riddleGiveUp => 'Never mind';

  @override
  String riddleSolvedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count riddles cracked so far',
      one: '1 riddle cracked so far',
      zero: 'Your first riddle',
    );
    return '$_temp0';
  }

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
  String get settingsSfxSubtitle => 'The little sounds as you play';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsHapticsSubtitle =>
      'A tick on every slide, a buzz on a bump';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

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

  @override
  String hudArrowsLeft(int out, int total) {
    return '$out of $total arrows out';
  }

  @override
  String hudTimeLeft(String time) {
    return '$time left on the clock';
  }

  @override
  String starsOfThree(int stars) {
    return '$stars of 3 stars';
  }

  @override
  String boardLabel(int width, int height, int left, int total) {
    return 'Puzzle board, $width by $height, $left of $total arrows left';
  }

  @override
  String arrowLabel(
    String direction,
    int length,
    int row,
    int column,
    String path,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length cells',
      one: '1 cell',
    );
    return 'Arrow pointing $direction, $_temp0 long, head at row $row, column $column. $path';
  }

  @override
  String get arrowPathClear => 'Clear path to the edge.';

  @override
  String get arrowPathMirror => 'Its path bounces off a mirror.';

  @override
  String arrowPathBlocked(int distance) {
    String _temp0 = intl.Intl.pluralLogic(
      distance,
      locale: localeName,
      other: 'Another arrow is $distance cells ahead.',
      one: 'Another arrow is right in front of it.',
    );
    return '$_temp0';
  }

  @override
  String get arrowHinted => 'Hint: this one can go.';

  @override
  String get arrowBumpedBefore => 'Bumped before; another bump here is free.';

  @override
  String arrowHiddenLabel(int length, int row, int column) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length cells',
      one: '1 cell',
    );
    return 'Arrow with a hidden head, $_temp0 long, from row $row, column $column. Which way it points shows once an arrow beside it leaves. Tapping it costs nothing: the board points at the arrow that uncovers it.';
  }

  @override
  String arrowLocked(int number) {
    return 'Lock $number: it also waits for key $number to leave.';
  }

  @override
  String arrowUnlocked(int number) {
    return 'Lock $number is open.';
  }

  @override
  String arrowKey(int number) {
    return 'Key $number: it opens lock $number.';
  }

  @override
  String get arrowTethered =>
      'Tethered to another arrow: the two leave together, so both paths must be clear.';

  @override
  String get arrowTapHint => 'Slide it out';

  @override
  String get directionUp => 'up';

  @override
  String get directionRight => 'right';

  @override
  String get directionDown => 'down';

  @override
  String get directionLeft => 'left';

  @override
  String get levelCleared => 'Cleared';

  @override
  String get levelUpNext => 'Up next';

  @override
  String levelBestTime(String time) {
    return 'best time $time';
  }

  @override
  String onboardStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get settingsMusicVolume => 'Music volume';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionSubtitle =>
      'No shakes, hops or confetti — the arrows still move';

  @override
  String get settingsExtraTime => 'Extra time';

  @override
  String get settingsExtraTimeSubtitle => 'Twice the clock on every level';

  @override
  String get chapterName6 => 'The Block';

  @override
  String get chapterBlurb6 =>
      'Six faces of arrows on a block. Turn it to reach each face.';

  @override
  String get introTitleCube => 'The block';

  @override
  String get introBodyCube =>
      'Six faces on one block. Turn it to play each face.';

  @override
  String get tutorialCube =>
      'Drag the block to turn it. Play the face in front; tap a side to bring it round.';

  @override
  String get cubeTurnLeft => 'Turn to the face on the left';

  @override
  String get cubeTurnRight => 'Turn to the face on the right';

  @override
  String get cubeTurnUp => 'Turn to the face above';

  @override
  String get cubeTurnDown => 'Turn to the face below';

  @override
  String cubeFaceArrows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrows on this face',
      one: '1 arrow on this face',
      zero: 'Face clear',
    );
    return '$_temp0';
  }

  @override
  String cubeFacesClear(int cleared, int total) {
    return '$cleared of $total faces clear';
  }

  @override
  String cubeMapLabel(int face, int cleared, int total) {
    return 'The block, face $face towards you, $cleared of $total faces clear';
  }

  @override
  String boardFaceLabel(int face, int width, int height, int left, int total) {
    return 'Face $face of the block, $width by $height, $left of $total arrows left on it';
  }
}
