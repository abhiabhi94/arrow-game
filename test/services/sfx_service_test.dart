import 'package:arrow_game/services/sfx_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_sfx.dart';

void main() {
  test('plays the whoosh at base pitch, climbing with quick successive exits', () {
    final backend = RecordingSfxBackend();
    var now = DateTime(2026, 1, 1, 12);
    final s = SfxService(() => true, backend: backend, now: () => now);
    s.whoosh();
    now = now.add(const Duration(milliseconds: 400));
    s.whoosh();
    now = now.add(const Duration(milliseconds: 400));
    s.whoosh();
    expect(backend.calls, ['$kWhooshSound@1.00', '$kWhooshSound@1.06', '$kWhooshSound@1.12']);
    expect(s.streak, 2);
  });

  test('the streak caps and resets after a pause', () {
    final backend = RecordingSfxBackend();
    var now = DateTime(2026, 1, 1, 12);
    final s = SfxService(() => true, backend: backend, now: () => now);
    for (var i = 0; i < 10; i++) {
      s.whoosh();
      now = now.add(const Duration(milliseconds: 100));
    }
    expect(s.streak, kWhooshStreakMax);
    expect(backend.calls.last, '$kWhooshSound@${(1 + kWhooshStreakMax * kWhooshStreakStep).toStringAsFixed(2)}');
    now = now.add(kWhooshStreakWindow + const Duration(milliseconds: 1));
    s.whoosh();
    expect(s.streak, 0);
    expect(backend.calls.last, '$kWhooshSound@1.00');
  });

  test('a bump knocks at base pitch and ends the streak', () {
    final backend = RecordingSfxBackend();
    var now = DateTime(2026, 1, 1, 12);
    final s = SfxService(() => true, backend: backend, now: () => now);
    s.whoosh();
    now = now.add(const Duration(milliseconds: 200));
    s.whoosh();
    expect(s.streak, 1);
    s.bump();
    expect(s.streak, 0);
    now = now.add(const Duration(milliseconds: 200));
    s.whoosh();
    expect(backend.calls, [
      '$kWhooshSound@1.00',
      '$kWhooshSound@1.06',
      '$kBumpSound@1.00',
      '$kWhooshSound@1.00',
    ]);
  });

  test('stays silent when disabled', () {
    final backend = RecordingSfxBackend();
    final s = SfxService(() => false, backend: backend);
    s.whoosh();
    s.bump();
    s.whoosh();
    expect(backend.calls, isEmpty);
  });

  test('warmUp builds the players up front, but only when effects are on', () async {
    final b = RecordingSfxBackend();
    var on = false;
    final s = SfxService(() => on, backend: b);
    await s.warmUp();
    expect(b.calls, isEmpty, reason: 'effects off: never touch the plugin');

    on = true;
    await s.warmUp();
    expect(b.calls, ['warmUp']);
  });
}
