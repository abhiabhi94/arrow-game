import 'package:arrow_game/services/sfx_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_sfx.dart';

void main() {
  test('plays the zip at base pitch, climbing with quick successive exits', () {
    final backend = RecordingSfxBackend();
    var now = DateTime(2026, 1, 1, 12);
    final s = SfxService(() => true, backend: backend, now: () => now);
    s.zip();
    now = now.add(const Duration(milliseconds: 400));
    s.zip();
    now = now.add(const Duration(milliseconds: 400));
    s.zip();
    expect(backend.calls, ['$kZipSound@1.00', '$kZipSound@1.06', '$kZipSound@1.12']);
    expect(s.streak, 2);
  });

  test('the streak caps and resets after a pause', () {
    final backend = RecordingSfxBackend();
    var now = DateTime(2026, 1, 1, 12);
    final s = SfxService(() => true, backend: backend, now: () => now);
    for (var i = 0; i < 10; i++) {
      s.zip();
      now = now.add(const Duration(milliseconds: 100));
    }
    expect(s.streak, kZipStreakMax);
    expect(backend.calls.last, '$kZipSound@${(1 + kZipStreakMax * kZipStreakStep).toStringAsFixed(2)}');
    now = now.add(kZipStreakWindow + const Duration(milliseconds: 1));
    s.zip();
    expect(s.streak, 0);
    expect(backend.calls.last, '$kZipSound@1.00');
  });

  test('stays silent when disabled', () {
    final backend = RecordingSfxBackend();
    final s = SfxService(() => false, backend: backend);
    s.zip();
    s.zip();
    expect(backend.calls, isEmpty);
  });
}
