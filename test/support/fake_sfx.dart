import 'package:arrow_game/services/sfx_service.dart';

class RecordingSfxBackend implements SfxBackend {
  final List<String> calls = <String>[];

  @override
  Future<void> play(String asset, {required double rate}) async =>
      calls.add('$asset@${rate.toStringAsFixed(2)}');

  @override
  Future<void> warmUp() async => calls.add('warmUp');
}
