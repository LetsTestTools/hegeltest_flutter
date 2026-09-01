import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  hegelFlutterTest('reverse is involutory', (tc) {
    final xs = tc.draw(lists(integers()));
    expect(xs.reversed.toList().reversed.toList(), equals(xs));
  });

  hegelFlutterTest('string round-trips through codeUnits', (tc) {
    final s = tc.draw(text());
    expect(String.fromCharCodes(s.codeUnits), equals(s));
  });

  hegelFlutterTest('addition is commutative', (tc) {
    final a = tc.draw(integers(min: -1000, max: 1000));
    final b = tc.draw(integers(min: -1000, max: 1000));
    expect(a + b, equals(b + a));
  });

  hegelFlutterStatefulTest('counter matches model', () => _CounterMachine());
}

class _CounterMachine extends StateMachine {
  int count = 0;
  final List<int> stack = [];

  @override
  List<StateRule> get rules => [
    StateRule(
      'push',
      execute: (tc) {
        final val = tc.draw(integers());
        stack.add(val);
        count++;
      },
    ),
    StateRule(
      'pop',
      precondition: () => count > 0,
      execute: (tc) {
        stack.removeLast();
        count--;
      },
    ),
  ];

  @override
  List<StateInvariant> get invariants => [
    StateInvariant(
      'count matches stack length',
      check: (tc) {
        expect(count, equals(stack.length));
      },
    ),
  ];
}
