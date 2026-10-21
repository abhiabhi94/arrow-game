import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every node in the semantics tree whose label matches [label], in tree
/// order. `find.bySemanticsLabel` only sees nodes that belong to a widget's
/// render object; the board's arrows are nodes a `CustomPainter` supplies,
/// so they have to be found by walking the tree itself.
List<SemanticsNode> semanticsNodes(WidgetTester tester, Pattern label) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (!node.isInvisible && !node.isMergedIntoParent) {
      final text = node.label;
      final matches = switch (label) {
        String() => text == label,
        _ => label.allMatches(text).isNotEmpty,
      };
      if (matches) out.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return out;
}

/// The one node labelled [label]; fails the test when there is not exactly one.
SemanticsNode semanticsNode(WidgetTester tester, Pattern label) {
  final nodes = semanticsNodes(tester, label);
  expect(nodes, hasLength(1), reason: 'nodes labelled $label');
  return nodes.single;
}

/// Performs [action] on [node] the way a screen reader would.
void performSemanticsAction(WidgetTester tester, SemanticsNode node, SemanticsAction action) =>
    node.owner!.performAction(node.id, action);
