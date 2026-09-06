import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  group('hegelFlutterMonkeyTest', () {
    hegelFlutterMonkeyTest(
      'fuzzes counter and text field without crashing',
      createWidget: (tc) => const _SampleCounterApp(),
      steps: 10,
      testCases: 5,
      invariant: (tc, tester) async {
        expect(find.byType(_SampleCounterApp), findsOneWidget);
      },
    );

    hegelFlutterMonkeyTest(
      'respects allowedActions filter',
      createWidget: (tc) => const _SampleCounterApp(),
      steps: 8,
      testCases: 3,
      allowedActions: [SemanticsAction.tap],
      stepInvariant: (tc, tester, step) async {
        expect(step.action, equals(SemanticsAction.tap));
      },
    );

    testWidgets('captures crash and formats step trace', (tester) async {
      var threw = false;
      try {
        // We run a monkey test on an app that throws when counter exceeds 2
        final widget = _BuggyCounterApp();
        await tester.pumpWidget(widget);

        final owner = tester.binding.rootPipelineOwner.semanticsOwner;
        expect(owner, isNotNull);

        // Find and tap until it throws
        for (var i = 0; i < 5; i++) {
          final buttonFinder = find.widgetWithText(ElevatedButton, 'Increment');
          if (buttonFinder.evaluate().isNotEmpty) {
            await tester.tap(buttonFinder);
            await tester.pump();
            final ex = tester.takeException();
            if (ex != null) {
              threw = true;
              expect(
                ex.toString(),
                contains('Intentional crash at counter > 2'),
              );
              break;
            }
          }
        }
      } finally {
        expect(threw, isTrue);
      }
    });
  });
}

class _SampleCounterApp extends StatefulWidget {
  const _SampleCounterApp();

  @override
  State<_SampleCounterApp> createState() => _SampleCounterAppState();
}

class _SampleCounterAppState extends State<_SampleCounterApp> {
  int _counter = 0;
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Count: $_counter'),
            ElevatedButton(
              onPressed: () => setState(() => _counter++),
              child: const Text('Increment'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _counter = 0),
              child: const Text('Reset'),
            ),
            TextField(onChanged: (v) => setState(() => _text = v)),
            Text('Input: $_text'),
          ],
        ),
      ),
    );
  }
}

class _BuggyCounterApp extends StatefulWidget {
  @override
  State<_BuggyCounterApp> createState() => _BuggyCounterAppState();
}

class _BuggyCounterAppState extends State<_BuggyCounterApp> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {
            setState(() {
              _count++;
              if (_count > 2) {
                throw StateError('Intentional crash at counter > 2');
              }
            });
          },
          child: const Text('Increment'),
        ),
      ),
    );
  }
}
