import 'package:arrow_game/services/haptics_service.dart';

/// Records every impulse so tests can assert on feedback without a platform.
class RecordingHapticEngine implements HapticEngine {
  final List<String> calls = <String>[];

  @override
  void selection() => calls.add('selection');
  @override
  void light() => calls.add('light');
  @override
  void medium() => calls.add('medium');
  @override
  void heavy() => calls.add('heavy');
  @override
  void vibrate() => calls.add('vibrate');
}
