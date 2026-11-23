import 'package:flutter_test/flutter_test.dart';

/// Thrown when one or more Flutter [AccessibilityGuideline] checks fail.
class AccessibilityViolationException implements Exception {
  /// Descriptions and failure reasons reported by each failed guideline.
  final List<String> violations;

  /// Creates an [AccessibilityViolationException] from failing guideline details.
  AccessibilityViolationException(List<String> violations)
    : violations = List.unmodifiable(violations);

  @override
  String toString() {
    final buf = StringBuffer('AccessibilityViolationException:\n');
    for (final v in violations) {
      buf.writeln('  - $v');
    }
    return buf.toString().trimRight();
  }
}

/// Default Flutter accessibility guidelines verified when checking semantics.
final List<AccessibilityGuideline> kDefaultA11yGuidelines = List.unmodifiable([
  androidTapTargetGuideline,
  iOSTapTargetGuideline,
  labeledTapTargetGuideline,
  textContrastGuideline,
]);

/// Evaluates Flutter [AccessibilityGuideline] checks against the widget tree
/// mounted in [tester].
///
/// Acquires a semantics handle for evaluation and disposes it when finished.
/// Defaults to [kDefaultA11yGuidelines] when [guidelines] is omitted.
/// Throws [AccessibilityViolationException] if any guideline fails.
Future<void> checkAccessibilityGuidelines(
  WidgetTester tester, {
  List<AccessibilityGuideline>? guidelines,
}) async {
  final effective = guidelines ?? kDefaultA11yGuidelines;
  if (effective.isEmpty) return;

  final semantics = tester.ensureSemantics();
  try {
    await tester.pump();
    final violations = <String>[];
    for (final guideline in effective) {
      final result = await guideline.evaluate(tester);
      if (!result.passed) {
        final reason = result.reason;
        violations.add(
          reason != null && reason.isNotEmpty
              ? '${guideline.description}: $reason'
              : guideline.description,
        );
      }
    }
    if (violations.isNotEmpty) {
      throw AccessibilityViolationException(violations);
    }
  } finally {
    semantics.dispose();
  }
}
