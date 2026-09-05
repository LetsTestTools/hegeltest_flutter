# hegeltest_flutter — Property-based testing for Flutter

[![pub package](https://img.shields.io/pub/v/hegeltest_flutter.svg)](https://pub.dev/packages/hegeltest_flutter)
[![CI](https://github.com/LetsTestTools/hegeltest_flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/LetsTestTools/hegeltest_flutter/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flutter integration for [hegeltest](https://pub.dev/packages/hegeltest) — property-based testing powered by Hegel's native fuzzing engine.

## Why this package?

`hegeltest` depends on `package:test`. Flutter projects use `flutter_test`. This package bridges the gap by providing `hegelFlutterTest()` which uses `flutter_test`'s `test()` function while giving you full access to all hegeltest generators.

## Quick Start

```yaml
dev_dependencies:
  hegeltest_flutter: ^0.7.0
  flutter_test:
    sdk: flutter
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  hegelFlutterTest('reverse is involutory', (tc) {
    final xs = tc.draw(lists(integers()));
    expect(xs.reversed.toList().reversed.toList(), equals(xs));
  });
}
```

Run with:
```bash
flutter test
```

## API

`hegelFlutterTest()` accepts all the same parameters as `hegelTest()`:

- `testCases` — number of random inputs to try (default: 100)
- `seed` — fixed seed for reproducibility
- `reproduce` — replay a specific failure blob
- `database` — whether to persist and replay counterexamples from disk (default: `true`)
- `databasePath` — custom path to store counterexamples (default: `.hegel/examples`)
- `databaseKey` — identifier for the test in the database (defaults to the test `description`)
- `config` — `HegelConfig` for reusable settings
- `setUpEach` / `tearDownEach` — per-iteration lifecycle hooks
- All `flutter_test` parameters: `timeout`, `tags`, `skip`, `retry`

All generators from `package:hegeltest` are re-exported:

- **Primitives**: `integers()`, `doubles()`, `booleans()`, `bigIntegers()`
- **Text**: `text()`, `fromRegex()`, `emails()`, `urls()`, `uuids()`
- **Collections**: `lists()`, `sets()`, `maps()`
- **Combinators**: `oneOf()`, `sampled()`, `nullable()`, `tuples2/3/4()`
- **Temporal**: `dates()`, `times()`, `dateTimes()`
- **Network**: `ipv4Addresses()`, `ipv6Addresses()`
- **Bytes**: `bytes()`

## Stateful Testing

For complex, state-dependent systems, `hegeltest_flutter` supports stateful property-based testing. This allows you to generate random sequences of operations and verify that your system invariants hold at every step:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

class Counter {
  int value = 0;
  void increment(int step) => value += step;
  void decrement(int step) => value -= step;
  void reset() => value = 0;
}

class CounterMachine extends StateMachine {
  final counter = Counter();
  int model = 0;

  @override
  List<StateRule> get rules => [
        StateRule('increment', execute: (tc) {
          final step = tc.draw(integers(min: 1, max: 10));
          counter.increment(step);
          model += step;
        }),
        StateRule('decrement', execute: (tc) {
          final step = tc.draw(integers(min: 1, max: 5));
          counter.decrement(step);
          model -= step;
        }),
        StateRule('reset', execute: (tc) {
          counter.reset();
          model = 0;
        }),
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
  hegelFlutterStatefulTest('counter works', () => CounterMachine());
}
```

## Widget Testing

`hegeltest_flutter` includes `hegelFlutterWidgetTest` which wraps `testWidgets()`, allowing you to run property-based tests on your Flutter UI. The callback receives both a `TestCase` (for drawing random values) and a `WidgetTester` (for pumping widgets).

Basic example: generating random text and verifying it renders without errors.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  hegelFlutterWidgetTest('text widget renders correctly', (tc, tester) async {
    final label = tc.draw(text(minSize: 1, maxSize: 50));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Text(label))));
    expect(find.text(label), findsOneWidget);
  });
}
```

Config sweep example: generate random widget configs, pump, and verify no overflow.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  hegelFlutterWidgetTest('padding does not cause overflow', (tc, tester) async {
    final left = tc.draw(integers(min: 0, max: 100)).toDouble();
    final top = tc.draw(integers(min: 0, max: 100)).toDouble();
    final right = tc.draw(integers(min: 0, max: 100)).toDouble();
    final bottom = tc.draw(integers(min: 0, max: 100)).toDouble();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(left, top, right, bottom),
            child: const SizedBox(width: 50, height: 50),
          ),
        ),
      ),
    );
    
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
```

## Standalone Runner

For custom testing tools, CI scripts, or programmatic analysis, use `runHegelFlutterTest()`. It returns a `RunResult` without wrapping inside `flutter_test`:

```dart
final result = await runHegelFlutterTest((tc) {
  final a = tc.draw(integers());
  final b = tc.draw(integers());
  assert(a + b == b + a);
});

print(result.status);       // RunStatus.passed
print(result.testCasesRun); // 100
```

## Collecting Statistics

Use `tc.collect()` to inspect the distribution of generated values across your test runs:

```dart
hegelFlutterTest('string reverse is involutory', (tc) {
  final s = tc.draw(text());
  tc.collect(
    s.isEmpty ? 'empty' : (s.length < 10 ? 'short' : 'long'),
    label: 'length',
  );
  expect(s.split('').reversed.join().split('').reversed.join(), equals(s));
}, verbosity: Verbosity.verbose);
```

When run with `verbosity: Verbosity.verbose`, distribution percentages are printed at the end of the test. When running programmatically with `runHegelFlutterTest()`, you can inspect `result.statistics` directly or format it with `result.formatStatistics()`.

## Persistent Counterexample Database

By default, `hegeltest_flutter` automatically caches discovered failing counterexamples to `.hegel/examples/` (scoped automatically by the test's `description`). On subsequent test runs, known failing examples are replayed **first** on iteration 1 during `Phase.reuse`, providing instant regression feedback before generating fresh random inputs.

To ensure your repository worktree stays clean, `hegeltest` automatically generates a `.gitignore` inside `.hegel/`.

You can configure or disable persistence:
* **Opt-out**: pass `database: false` or set the environment variable `HEGEL_DATABASE=0` to disable disk persistence and replay.
* **Custom storage path**: pass `databasePath: '.custom_db/'` to store counterexamples in an alternative directory.
* **Stable scoping**: pass `databaseKey: 'my_stable_key'` to preserve cache continuity even if a test description changes.

In CI pipelines (e.g. GitHub Actions), cache `.hegel/` to catch regressions from previous runs instantly:
```yaml
- name: Cache Hegel counterexamples
  uses: actions/cache@v4
  with:
    path: .hegel/
    key: hegel-${{ runner.os }}-${{ github.ref_name }}
    restore-keys: hegel-${{ runner.os }}-
```

## Platform Support

| Platform | Status |
|----------|--------|
| macOS arm64 | ✅ |
| Linux x64 | ✅ |
| Linux arm64 | ✅ |
| Windows x64 | ✅ |
| Windows arm64 | ✅ |
| Web | ❌ (throws `UnsupportedError`) |

## License

MIT. See [LICENSE](LICENSE).
