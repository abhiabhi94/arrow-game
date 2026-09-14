import 'package:arrow_game/ui/layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contentGutter', () {
    test('splits the slack either side of a wide window', () {
      expect(contentGutter(1440).horizontal, 1440 - kMaxContentWidth);
      expect(contentGutter(1440).left, (1440 - kMaxContentWidth) / 2);
    });

    test('is nothing on a window narrower than the content column', () {
      expect(contentGutter(390).horizontal, 0);
    });

    test('never drops below the minimum', () {
      expect(contentGutter(390, minimum: 24).left, 24);
    });
  });

  testWidgets('ContentColumn centres its child in a phone-width column', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: ContentColumn(child: SizedBox.expand(key: Key('content'))),
      ),
    );
    final rect = tester.getRect(find.byKey(const Key('content')));
    expect(rect.width, kMaxContentWidth);
    expect(rect.left, (1440 - kMaxContentWidth) / 2);
    expect(rect.height, 900);
  });

  test('AppScrollBehavior scrolls from a mouse drag too', () {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
  });

  testWidgets('AppScrollBehavior lets a mouse drag scroll a list', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: ListView(
          controller: controller,
          children: List<Widget>.generate(
            40,
            (i) => SizedBox(height: 80, child: Text('row $i')),
          ),
        ),
      ),
    );

    await tester.drag(
      find.text('row 0'),
      const Offset(0, -200),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(controller.offset, greaterThan(0));
  });
}
