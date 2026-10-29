import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../data/level_specs.dart';
import '../providers/progress_provider.dart' show testingUnlocksAllLevels;

/// Hooks for profiling the web build (`tool/perf.mjs`), alive only in a
/// build with every level open (a debug build, or `UNLOCK_ALL=true` — the
/// PR previews) and only on a page opened with `?perf`: the store build
/// never sees them.
///
/// `?level=N` opens level N straight away rather than home — so the
/// profiler plays a level the way a player does, without the semantics
/// tree the screenshot harness has to switch on to find the trail's
/// buttons (it is real work on a board of two hundred arrows) — and
/// [perfMark] prints `perf:<name>` to the console, which the profiler
/// reads as the moment a level started dealing and the moment its board
/// arrived.
bool get perfHooksOn => kIsWeb && testingUnlocksAllLevels && Uri.base.queryParameters.containsKey('perf');

/// The level [uri] asks to open at (`?level=N`), when [allowed] and N is a
/// level; otherwise null.
int? startLevelFrom(Uri uri, {required bool allowed}) {
  if (!allowed) return null;
  final level = int.tryParse(uri.queryParameters['level'] ?? '');
  return level != null && level >= 1 && level <= totalLevels ? level : null;
}

/// Prints `perf:<name>` for the profiler, when [perfHooksOn].
void perfMark(String name) {
  if (perfHooksOn) debugPrint('perf:$name'); // coverage:ignore-line
}

/// Reports every frame's build and raster time to the profiler, as
/// `perf:frames b1/r1 b2/r2 …` in microseconds, when [perfHooksOn]. The
/// build time is the Dart work of a frame — the same on a phone as here —
/// and is what the profiler budgets; the raster time on a runner with no
/// GPU says little about a phone, which draws on its GPU.
void reportFrameTimings() {
  // coverage:ignore-start
  if (!perfHooksOn) return;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    debugPrint('perf:frames ${timings.map((t) => '${t.buildDuration.inMicroseconds}/${t.rasterDuration.inMicroseconds}').join(' ')}');
  });
  // coverage:ignore-end
}
