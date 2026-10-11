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

  hegelFlutterTest('supports tc.cover, tc.classify, and weighted sampling', (
    tc,
  ) {
    final flag = tc.draw(sampledWeighted([(7, true), (3, false)]));
    final num = tc.draw(
      oneOfWeighted([
        (8, integers(min: 0, max: 10)),
        (2, integers(min: 100, max: 200)),
      ]),
    );

    tc.classify(flag, 'flag_true');
    tc.classify(!flag, 'flag_false');
    // flag is true ~70% of the time, require at least 40%
    tc.cover(40.0, flag, 'flag_coverage');

    expect(num, greaterThanOrEqualTo(0));
  });

  hegelFlutterWidgetTest(
    'resets StatefulWidget state between iterations',
    testCases: 5,
    (tc, tester) async {
      final delta = tc.draw(integers(min: 1, max: 10));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _StatefulAccumulator(delta: delta),
        ),
      );
      expect(find.text('Total: $delta'), findsOneWidget);
    },
  );

  testWidgets(
    'widget test catches and shrinks Flutter framework exceptions cleanly',
    (tester) async {
      var minFailingWidth = double.infinity;
      final result = await runHegelFlutterTest(
        (tc) async {
          final width = tc.draw(integers(min: 100, max: 500)).toDouble();
          try {
            await tester.pumpWidget(SizedBox.shrink(key: UniqueKey()));
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: Row(
                      children: [
                        SizedBox(
                          width: width,
                          height: 50,
                          child: const Text('X'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            final dynamic pendingException = tester.takeException();
            if (pendingException != null) {
              if (width < minFailingWidth) {
                minFailingWidth = width;
              }
              if (pendingException is Error &&
                  pendingException.stackTrace != null) {
                Error.throwWithStackTrace(
                  pendingException,
                  pendingException.stackTrace!,
                );
              }
              throw pendingException as Object;
            }
          } finally {
            while (tester.takeException() != null) {}
          }
        },
        testCases: 20,
        seed: 42,
        database: false,
      );

      expect(
        result.status,
        equals(RunStatus.failed),
        reason: result.errorMessage,
      );
      // Shrunk counterexample should be 201 (the minimal integer > 200 causing overflow)
      expect(minFailingWidth, equals(201.0));
      expect(result.failures, isNotEmpty);
      expect(result.failures.first.reproductionBlob, isNotEmpty);
    },
  );
}

class _StatefulAccumulator extends StatefulWidget {
  final int delta;
  const _StatefulAccumulator({required this.delta});

  @override
  State<_StatefulAccumulator> createState() => _StatefulAccumulatorState();
}

class _StatefulAccumulatorState extends State<_StatefulAccumulator> {
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _total += widget.delta;
  }

  @override
  void didUpdateWidget(covariant _StatefulAccumulator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If State were reused across iterations, _total would accumulate!
    _total += widget.delta;
  }

  @override
  Widget build(BuildContext context) {
    return Text('Total: $_total');
  }
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
