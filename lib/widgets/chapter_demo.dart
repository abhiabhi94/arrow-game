import 'dart:async';

import 'package:flutter/material.dart';

import '../data/chapter_demos.dart';
import '../data/chapters.dart';
import '../engine/cube.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../ui/motion.dart';
import 'cube_stage.dart';
import 'puzzle_board.dart';

/// How long between the taps the demo plays, and how long it rests on the
/// cleared board before starting over.
const Duration kDemoStep = Duration(milliseconds: 1400);
const Duration kDemoRest = Duration(milliseconds: 1800);

/// A chapter's twist, played out on a small board: the demo taps its own
/// arrows one by one — the way the card's line says to — and starts over
/// when the board is clear, so the rule is watched rather than read. The
/// board is a picture to the finger and to a screen reader (the line above
/// it says what it shows). With motion reduced it stands still on its
/// first frame. The block's card turns the block to each arrow's face
/// before it plays it.
class ChapterDemoBoard extends StatefulWidget {
  const ChapterDemoBoard({super.key, required this.rule, this.height = 132});

  final ChapterRule rule;
  final double height;

  @override
  State<ChapterDemoBoard> createState() => _ChapterDemoBoardState();
}

class _ChapterDemoBoardState extends State<ChapterDemoBoard> {
  late final GameNotifier _game = GameNotifier(
    demoSpecFor(widget.rule),
    puzzle: demoPuzzleFor(widget.rule),
    autoTick: false,
  );
  late GameState _state;
  late final void Function() _unsubscribe;
  Timer? _timer;
  int _step = 0;
  CubeView _view = const CubeView();
  CubeTurn? _lastTurn;

  @override
  void initState() {
    super.initState();
    _unsubscribe = _game.addListener((s) => setState(() => _state = s));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && !reduceMotionOf(context)) _schedule(kDemoStep);
  }

  void _schedule(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, _advance);
  }

  /// Plays the next tap of the script, or rests and starts over.
  void _advance() {
    if (!mounted) return;
    final script = demoScriptFor(widget.rule);
    if (_step >= script.length) {
      _step = 0;
      _game.restart();
      _schedule(kDemoStep);
      return;
    }
    final puzzle = _state.puzzle!;
    final id = script[_step];
    if (puzzle.isCube && puzzle.faceOf(id) != _view.front) {
      // Round to the arrow's face first, then play it.
      final turn = _view.pathTo(puzzle.faceOf(id)).first;
      setState(() {
        _view = _view.turned(turn);
        _lastTurn = turn;
      });
      _schedule(kCubeTurn + const Duration(milliseconds: 400));
      return;
    }
    _game.tapArrow(id);
    _step++;
    _schedule(_step >= script.length ? kDemoRest : kDemoStep);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _unsubscribe();
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
          child: SizedBox(
            height: widget.height,
            child: _state.puzzle!.isCube
                ? CubeStage(
                    view: _view,
                    lastTurn: _lastTurn,
                    reduceMotion: reduceMotionOf(context),
                    faceBuilder: (context, face) => PuzzleBoard(
                      state: _state,
                      face: face,
                      showGrid: true,
                      onTapArrow: (_) {},
                      reduceMotion: reduceMotionOf(context),
                    ),
                  )
                : PuzzleBoard(
                    state: _state,
                    showGrid: true,
                    onTapArrow: (_) {},
                    reduceMotion: reduceMotionOf(context),
                  ),
          ),
        ),
      );
}
