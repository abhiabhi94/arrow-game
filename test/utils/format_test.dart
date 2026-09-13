import 'package:arrow_game/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDurationMs renders m:ss', () {
    expect(formatDurationMs(0), '0:00');
    expect(formatDurationMs(999), '0:00');
    expect(formatDurationMs(67000), '1:07');
    expect(formatDurationMs(-5), '0:00');
  });

  test('formatTimeLeft is m:ss and rounds up so 0:00 only shows when time is gone', () {
    expect(formatTimeLeft(30000), '0:30');
    expect(formatTimeLeft(29999), '0:30');
    expect(formatTimeLeft(67001), '1:08');
    expect(formatTimeLeft(693000), '11:33');
    expect(formatTimeLeft(1), '0:01');
    expect(formatTimeLeft(0), '0:00');
    expect(formatTimeLeft(-100), '0:00');
  });
}
