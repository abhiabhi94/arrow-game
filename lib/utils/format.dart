/// Small formatting helpers. Pure Dart.
library;

/// Formats a duration in milliseconds as `m:ss` (e.g. 1:07).
String formatDurationMs(int milliseconds) {
  final totalSeconds = (milliseconds < 0 ? 0 : milliseconds) ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Formats a millisecond countdown as `m:ss`, rounding up so the clock only
/// shows 0:00 once the time is truly gone (e.g. 29 999 ms -> "0:30").
String formatTimeLeft(int milliseconds) {
  if (milliseconds <= 0) return '0:00';
  return formatDurationMs(((milliseconds + 999) ~/ 1000) * 1000);
}
