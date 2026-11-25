// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

class _TodoItemWidget extends StatefulWidget {
  const _TodoItemWidget();

  @override
  State<_TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<_TodoItemWidget> {
  final _items = <String>[];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Count: ${_items.length}'),
            TextField(key: const Key('todo_input'), controller: _controller),
            ElevatedButton(
              onPressed: () {
                final label = _controller.text;
                if (label.isEmpty || _items.contains(label)) return;
                setState(() {
                  _items.add(label);
                  _controller.clear();
                });
              },
              child: const Text('Add'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _items)
                  OutlinedButton(
                    onPressed: () => setState(() => _items.remove(item)),
                    child: Text('Remove $item'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoWidgetMachine extends WidgetStateMachine {
  final model = <String>[];
  late final Pool<String> itemsPool;
  int _nextId = 0;

  @override
  int get stepCount => 8;

  @override
  void setUp(WidgetTester tester) {
    itemsPool = createPool<String>();
  }

  @override
  Widget buildInitialWidget(TestCase tc) => const _TodoItemWidget();

  @override
  List<WidgetStateRule> get rules => [
    WidgetStateRule(
      'add item',
      weight: 3.0,
      execute: (tester, tc) async {
        final suffix = tc.draw(
          text(minCodepoint: 0x61, maxCodepoint: 0x7a, minSize: 2, maxSize: 4),
          label: 'item_suffix',
        );
        final label = 'i${_nextId++}_$suffix';
        await tester.enterText(find.byKey(const Key('todo_input')), label);
        await tester.tap(find.text('Add'));
        await tester.pump();
        model.add(label);
        itemsPool.add(label);
      },
    ),
    WidgetStateRule(
      'remove item',
      precondition: () => model.isNotEmpty,
      execute: (tester, tc) async {
        final label = tc.draw(itemsPool.consumed, label: 'removed_item');
        await tester.tap(find.text('Remove $label'));
        await tester.pump();
        expect(model.remove(label), isTrue);
      },
    ),
  ];

  @override
  List<WidgetStateInvariant> get invariants => [
    WidgetStateInvariant(
      'ui count matches model',
      check: (tester, tc) {
        expect(find.text('Count: ${model.length}'), findsOneWidget);
      },
    ),
    WidgetStateInvariant(
      'ui buttons match model (sampled)',
      alwaysCheck: false,
      check: (tester, tc) {
        for (final item in model) {
          expect(find.text('Remove $item'), findsOneWidget);
        }
      },
    ),
  ];
}

class _BuggyCounterWidget extends StatefulWidget {
  const _BuggyCounterWidget();

  @override
  State<_BuggyCounterWidget> createState() => _BuggyCounterWidgetState();
}

class _BuggyCounterWidgetState extends State<_BuggyCounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final display = _count >= 3 ? 999 : _count;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text('Count: $display'),
          GestureDetector(
            onTap: () => setState(() => _count++),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Increment'),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _count = 0),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuggyCounterMachine extends WidgetStateMachine {
  int expected = 0;

  @override
  int get stepCount => 5;

  @override
  Widget buildInitialWidget(TestCase tc) => const _BuggyCounterWidget();

  @override
  List<WidgetStateRule> get rules => [
    WidgetStateRule(
      'increment',
      execute: (tester, tc) async {
        await tester.tap(find.text('Increment'));
        await tester.pump();
        expected++;
      },
    ),
    WidgetStateRule(
      'reset',
      execute: (tester, tc) async {
        await tester.tap(find.text('Reset'));
        await tester.pump();
        expected = 0;
      },
    ),
  ];

  @override
  List<WidgetStateInvariant> get invariants => [
    WidgetStateInvariant(
      'count matches expected',
      check: (tester, tc) {
        expect(find.text('Count: $expected'), findsOneWidget);
      },
    ),
  ];
}

class _ExceptionWidget extends StatelessWidget {
  const _ExceptionWidget();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () => throw FlutterError('boom in button callback'),
          child: const Text('Explode'),
        ),
      ),
    );
  }
}

class _ExceptionRuleMachine extends WidgetStateMachine {
  @override
  int get stepCount => 3;

  @override
  Widget buildInitialWidget(TestCase tc) => const _ExceptionWidget();

  @override
  List<WidgetStateRule> get rules => [
    WidgetStateRule(
      'explode',
      execute: (tester, tc) async {
        await tester.tap(find.text('Explode'));
        await tester.pump();
      },
    ),
  ];
}

class _FailingTearDownMachine extends WidgetStateMachine {
  @override
  int get stepCount => 2;

  @override
  Widget buildInitialWidget(TestCase tc) => const MaterialApp(home: SizedBox());

  @override
  List<WidgetStateRule> get rules => [
    WidgetStateRule('noop', execute: (tester, tc) async {}),
  ];

  @override
  void tearDown(WidgetTester tester) {
    throw StateError('widget tearDown failed');
  }
}

class _ThrowingTearDownPumpMachine extends WidgetStateMachine {
  @override
  int get stepCount => 2;

  @override
  Widget buildInitialWidget(TestCase tc) => const SizedBox();

  @override
  List<WidgetStateRule> get rules => [
    WidgetStateRule('noop', execute: (tester, tc) async {}),
  ];

  @override
  Future<void> tearDown(WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (_) {
          throw FlutterError('tearDown widget boom');
        },
      ),
    );
  }
}

class _DisposeThrowsWidget extends StatefulWidget {
  const _DisposeThrowsWidget();

  @override
  State<_DisposeThrowsWidget> createState() => _DisposeThrowsWidgetState();
}

class _DisposeThrowsWidgetState extends State<_DisposeThrowsWidget> {
  @override
  void dispose() {
    super.dispose();
    throw FlutterError('dispose widget boom');
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _ThrowingDisposeMachine extends WidgetStateMachine {
  @override
  int get stepCount => 2;

  @override
  Widget buildInitialWidget(TestCase tc) => const _DisposeThrowsWidget();

  @override
  List<WidgetStateRule> get rules => [
    WidgetStateRule('noop', execute: (tester, tc) async {}),
  ];
}

void main() {
  group('WidgetStateMachine & hegelFlutterStatefulWidgetTest', () {
    hegelFlutterStatefulWidgetTest(
      'todo widget preserves model & pool invariants across operations',
      () => _TodoWidgetMachine(),
      testCases: 10,
      database: false,
    );

    testWidgets(
      'failing stateful widget shrinks and reports tc.note() step trace',
      (tester) async {
        final result = await runHegelFlutterStatefulWidgetTest(
          tester,
          () => _BuggyCounterMachine(),
          testCases: 30,
          database: false,
        );

        expect(result.status, equals(RunStatus.failed));
        final message = result.failures.first.message;
        expect(message, contains('Notes:'));
        expect(message, contains('step 1:'));
        expect(message, contains('increment'));
      },
    );

    testWidgets(
      'captures pending Flutter framework exceptions triggered inside rules',
      (tester) async {
        final result = await runHegelFlutterStatefulWidgetTest(
          tester,
          () => _ExceptionRuleMachine(),
          testCases: 5,
          phases: {Phase.generate},
          database: false,
        );

        expect(result.status, equals(RunStatus.failed));
        expect(
          result.failures.first.message,
          contains('boom in button callback'),
        );
      },
    );

    testWidgets('propagates tearDown error when rule execution passes', (
      tester,
    ) async {
      final result = await runHegelFlutterStatefulWidgetTest(
        tester,
        () => _FailingTearDownMachine(),
        testCases: 3,
        phases: {Phase.generate},
        database: false,
      );

      expect(result.status, equals(RunStatus.failed));
      expect(result.failures.first.message, contains('widget tearDown failed'));
    });

    testWidgets(
      'propagates pending framework exception pumped during tearDown',
      (tester) async {
        final result = await runHegelFlutterStatefulWidgetTest(
          tester,
          () => _ThrowingTearDownPumpMachine(),
          testCases: 2,
          phases: {Phase.generate},
          database: false,
        );

        expect(result.status, equals(RunStatus.failed));
        expect(result.failures.first.message, contains('tearDown widget boom'));
      },
    );

    testWidgets('propagates framework exception thrown during widget dispose', (
      tester,
    ) async {
      final result = await runHegelFlutterStatefulWidgetTest(
        tester,
        () => _ThrowingDisposeMachine(),
        testCases: 2,
        phases: {Phase.generate},
        database: false,
      );

      expect(result.status, equals(RunStatus.failed));
      expect(result.failures.first.message, contains('dispose widget boom'));
    });

    test('validates rule weight and createPool lifecycle', () {
      for (final bad in [0.0, -2.0, double.nan, double.infinity]) {
        expect(
          () => WidgetStateRule('bad', weight: bad, execute: (_, __) {}),
          throwsArgumentError,
        );
      }

      final machine = _TodoWidgetMachine();
      expect(() => machine.createPool<String>(), throwsStateError);
    });
  });
}
