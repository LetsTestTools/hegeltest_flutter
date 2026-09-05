import 'dart:io';

import 'package:flutter/widgets.dart';
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

  hegelFlutterWidgetTest('text widget renders correctly', (tc, tester) async {
    final s = tc.draw(text());
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: Text(s)),
    );
    expect(find.text(s), findsOneWidget);
  });

  hegelFlutterWidgetTest('padding does not cause overflow', (tc, tester) async {
    final left = tc.draw(integers(min: 0, max: 100)).toDouble();
    final top = tc.draw(integers(min: 0, max: 100)).toDouble();
    final right = tc.draw(integers(min: 0, max: 100)).toDouble();
    final bottom = tc.draw(integers(min: 0, max: 100)).toDouble();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(left, top, right, bottom),
            child: const SizedBox(width: 50, height: 50),
          ),
        ),
      ),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });

  test(
    'persistent database writes counterexample and replays on iteration 1',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('hegel_flutter_db_');
      try {
        final dbPath = tempDir.path;
        final res1 = await runHegelFlutterTest(
          (tc) {
            final x = tc.draw(integers(min: 1, max: 100));
            expect(x, isNegative);
          },
          database: true,
          databasePath: dbPath,
          databaseKey: 'flutter_db_fail',
        );

        expect(res1.status, equals(RunStatus.failed));
        final files = Directory(dbPath).listSync().whereType<File>().toList();
        expect(files, isNotEmpty);

        // Replay: counterexample replayed on iteration 1
        final res2 = await runHegelFlutterTest(
          (tc) {
            final x = tc.draw(integers(min: 1, max: 100));
            expect(x, isNegative);
          },
          database: true,
          databasePath: dbPath,
          databaseKey: 'flutter_db_fail',
        );

        expect(res2.status, equals(RunStatus.failed));
        expect(res2.testCasesRun, equals(1));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    },
  );

  test('database: false disables counterexample persistence', () async {
    final tempDir = Directory.systemTemp.createTempSync('hegel_flutter_nodb_');
    try {
      final dbPath = '${tempDir.path}/disabled_db';
      final res = await runHegelFlutterTest(
        (tc) {
          final x = tc.draw(integers(min: 1, max: 100));
          expect(x, isNegative);
        },
        database: false,
        databasePath: dbPath,
        databaseKey: 'flutter_nodb_fail',
      );

      expect(res.status, equals(RunStatus.failed));
      expect(Directory(dbPath).existsSync(), isFalse);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  hegelFlutterTest('supports database parameter and config', (tc) {
    final n = tc.draw(integers());
    expect(n + 0, equals(n));
  }, database: true);
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
