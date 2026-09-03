import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

/// System under test (SUT) with internal business logic.
class Counter {
  int value = 0;
  void increment(int step) => value += step;
  void decrement(int step) => value -= step;
  void reset() => value = 0;
}

/// Model-based state machine that exercises [Counter] and asserts
/// its state against a simplified independent model.
class CounterMachine extends StateMachine {
  final counter = Counter();
  int model = 0;

  @override
  List<StateRule> get rules => [
    StateRule(
      'increment',
      execute: (tc) {
        final step = tc.draw(integers(min: 1, max: 10));
        counter.increment(step);
        model += step;
      },
    ),
    StateRule(
      'decrement',
      execute: (tc) {
        final step = tc.draw(integers(min: 1, max: 5));
        counter.decrement(step);
        model -= step;
      },
    ),
    StateRule(
      'reset',
      execute: (tc) {
        counter.reset();
        model = 0;
      },
    ),
  ];

  @override
  List<StateInvariant> get invariants => [
    StateInvariant(
      'counter value matches model',
      check: (tc) {
        expect(counter.value, equals(model));
      },
    ),
  ];
}

void main() {
  // 1. Unit property test with flutter_test
  hegelFlutterTest('string reverse is involutory', (tc) {
    final s = tc.draw(text());
    expect(s.split('').reversed.join().split('').reversed.join(), equals(s));
  });

  // 2. Widget property testing: generate random text and verify rendering
  hegelFlutterWidgetTest('text renders correctly without throwing', (
    tc,
    tester,
  ) async {
    final label = tc.draw(text(minSize: 1, maxSize: 50));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text(label))),
      ),
    );
    expect(find.text(label), findsOneWidget);
  });

  // 3. Widget property testing: padding configuration sweep
  hegelFlutterWidgetTest('random padding does not overflow', (
    tc,
    tester,
  ) async {
    final left = tc.draw(integers(min: 0, max: 64)).toDouble();
    final top = tc.draw(integers(min: 0, max: 64)).toDouble();
    final right = tc.draw(integers(min: 0, max: 64)).toDouble();
    final bottom = tc.draw(integers(min: 0, max: 64)).toDouble();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(left, top, right, bottom),
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });

  // 4. Stateful model-based testing
  hegelFlutterStatefulTest('counter machine preserves model invariant', () {
    return CounterMachine();
  });
}
