import 'package:arrow_game/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDurationMs renders m:ss', () {
    expect(formatDurationMs(0), '0:00');
    expect(formatDurationMs(999), '0:00');
    expect(formatDurationMs(67000), '1:07');
    expect(formatDurationMs(-5), '0:00');
  });

  test('formatSecondsLeft rounds up so 0 only shows when time is gone', () {
    expect(formatSecondsLeft(30000), '30');
    expect(formatSecondsLeft(29999), '30');
    expect(formatSecondsLeft(1), '1');
    expect(formatSecondsLeft(0), '0');
    expect(formatSecondsLeft(-100), '0');
  });
}
