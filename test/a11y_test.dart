import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  group('Accessibility guideline checks', () {
    testWidgets('accessible widget passes kDefaultA11yGuidelines', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 48),
                ),
                onPressed: () {},
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      );

      await checkAccessibilityGuidelines(tester);
    });

    testWidgets(
      'unlabeled IconButton fails labeledTapTargetGuideline with AccessibilityViolationException',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        );

        late final AccessibilityViolationException caught;
        try {
          await checkAccessibilityGuidelines(
            tester,
            guidelines: [labeledTapTargetGuideline],
          );
          fail('Expected AccessibilityViolationException');
        } on AccessibilityViolationException catch (e) {
          caught = e;
        }
        expect(caught.violations, isNotEmpty);
      },
    );

    testWidgets('undersized tap target fails androidTapTargetGuideline', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: InkWell(
                  onTap: () {},
                  child: Semantics(
                    label: 'Tiny button',
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      late final AccessibilityViolationException caught;
      try {
        await checkAccessibilityGuidelines(
          tester,
          guidelines: [androidTapTargetGuideline],
        );
        fail('Expected AccessibilityViolationException');
      } on AccessibilityViolationException catch (e) {
        caught = e;
      }
      expect(caught.toString(), contains('AccessibilityViolationException:'));
    });

    testWidgets(
      'works cleanly across multiple property iterations via runHegelFlutterWidgetTest',
      (tester) async {
        final passResult = await runHegelFlutterWidgetTest(
          tester,
          (tc, tester) async {
            final label = tc.draw(
              text(
                minCodepoint: 0x61,
                maxCodepoint: 0x7a,
                minSize: 3,
                maxSize: 10,
              ),
            );
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(64, 48),
                      ),
                      onPressed: () {},
                      child: Text(label),
                    ),
                  ),
                ),
              ),
            );
            await checkAccessibilityGuidelines(
              tester,
              guidelines: [
                androidTapTargetGuideline,
                labeledTapTargetGuideline,
                textContrastGuideline,
              ],
            );
          },
          testCases: 6,
          database: false,
        );
        expect(passResult.status, equals(RunStatus.passed));

        final failResult = await runHegelFlutterWidgetTest(
          tester,
          (tc, tester) async {
            tc.draw(booleans());
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            );
            await checkAccessibilityGuidelines(
              tester,
              guidelines: [labeledTapTargetGuideline],
            );
          },
          testCases: 5,
          database: false,
        );
        expect(failResult.status, equals(RunStatus.failed));
        expect(
          failResult.failures.first.message,
          contains('AccessibilityViolationException'),
        );
      },
    );

    final sweepRecording = _RecordingGuideline();
    hegelFlutterLayoutSweepTest(
      'layout sweep integrates optional accessibilityGuidelines',
      testCases: 5,
      database: false,
      accessibilityGuidelines: [sweepRecording],
      builder: (tc, sample) => Scaffold(
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      ),
      invariant: (tc, tester, sample) {
        expect(sweepRecording.evaluateCount, greaterThan(0));
      },
    );

    final monkeyRecording = _RecordingGuideline();
    hegelFlutterMonkeyTest(
      'monkey test integrates optional accessibilityGuidelines',
      createWidget: (tc) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () {},
              child: const Text('Action'),
            ),
          ),
        ),
      ),
      steps: 4,
      testCases: 5,
      database: false,
      accessibilityGuidelines: [monkeyRecording],
      invariant: (tc, tester) {
        expect(monkeyRecording.evaluateCount, greaterThan(0));
      },
    );
  });
}

class _RecordingGuideline extends AccessibilityGuideline {
  int evaluateCount = 0;

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) {
    evaluateCount++;
    return labeledTapTargetGuideline.evaluate(tester);
  }

  @override
  String get description =>
      'Recording(${labeledTapTargetGuideline.description})';
}
