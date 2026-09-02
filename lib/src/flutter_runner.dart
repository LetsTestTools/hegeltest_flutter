import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest/hegeltest.dart';
import 'package:hegeltest/src/stateful/stateful_runner.dart';

/// Property-based test function for Flutter, powered by Hegel's native engine.
///
/// This is the Flutter equivalent of `hegelTest` from `package:hegeltest`.
/// It uses `flutter_test`'s `test()` instead of `package:test`'s `test()`,
/// making it compatible with `flutter test`.
///
/// ```dart
/// import 'package:hegeltest_flutter/hegeltest_flutter.dart';
/// import 'package:flutter_test/flutter_test.dart';
///
/// void main() {
///   hegelFlutterTest('addition is commutative', (tc) {
///     final a = tc.draw(integers());
///     final b = tc.draw(integers());
///     expect(a + b, equals(b + a));
///   });
/// }
/// ```
void hegelFlutterTest(
  String description,
  FutureOr<void> Function(TestCase tc) body, {
  Timeout? timeout,
  dynamic tags,
  dynamic skip,
  Map<String, dynamic>? onPlatform,
  int? retry,
  HegelConfig? config,
  int? testCases,
  int? seed,
  bool? derandomize,
  Set<Phase>? phases,
  Verbosity? verbosity,
  Set<HealthCheck>? suppressHealthChecks,
  bool? reportMultipleFailures,
  String? reproduce,
  String? databaseKey,
  String? database,
  FutureOr<void> Function()? setUpEach,
  FutureOr<void> Function()? tearDownEach,
}) {
  // Uses flutter_test's test() instead of package:test's test().
  test(
    description,
    () async {
      final lib = loadHegelLibrary();
      final runner = HegelRunner(lib);
      await runner.run(
        body,
        reproduceBlob: reproduce ?? config?.reproduce,
        testCases: testCases ?? config?.testCases,
        seed: seed ?? config?.seed ?? _envSeed(),
        derandomize: derandomize ?? config?.derandomize,
        phases: phases ?? config?.phases,
        verbosity: verbosity ?? config?.verbosity,
        suppressHealthChecks:
            suppressHealthChecks ?? config?.suppressHealthChecks,
        reportMultipleFailures:
            reportMultipleFailures ?? config?.reportMultipleFailures,
        databaseKey: databaseKey ?? config?.databaseKey,
        database: database ?? config?.database,
        setUpEach: setUpEach,
        tearDownEach: tearDownEach,
      );
    },
    timeout: timeout ?? const Timeout(Duration(minutes: 10)),
    tags: tags,
    skip: skip,
    onPlatform: onPlatform,
    retry: retry,
  );
}

int? _envSeed() {
  final raw = Platform.environment['HEGEL_SEED'];
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
}

/// Stateful property-based test function for Flutter.
///
/// This is the Flutter equivalent of `hegelStatefulTest` from `package:hegeltest`.
/// Uses `flutter_test`'s `test()` instead of `package:test`'s `test()`.
///
/// ```dart
/// import 'package:hegeltest_flutter/hegeltest_flutter.dart';
/// import 'package:flutter_test/flutter_test.dart';
///
/// void main() {
///   hegelFlutterStatefulTest('stack works', () => StackMachine());
/// }
/// ```
void hegelFlutterStatefulTest(
  String description,
  StateMachine Function() create, {
  Timeout? timeout,
  dynamic tags,
  dynamic skip,
  Map<String, dynamic>? onPlatform,
  int? retry,
  HegelConfig? config,
  int? testCases,
  int? seed,
  bool? derandomize,
  Set<Phase>? phases,
  Verbosity? verbosity,
  Set<HealthCheck>? suppressHealthChecks,
  bool? reportMultipleFailures,
  String? reproduce,
  String? databaseKey,
  String? database,
}) {
  test(
    description,
    () async {
      final lib = loadHegelLibrary();
      final runner = HegelRunner(lib);

      await runner.run(
        (tc) async {
          final machine = create();
          try {
            await machine.setUp();
            await runStateMachine(lib, tc.ctx, tc.handle, machine, tc);
          } finally {
            try {
              await machine.tearDown();
            } catch (e, st) {
              stderr.writeln('[hegeltest_flutter] tearDown threw: $e\n$st');
            }
          }
        },
        reproduceBlob: reproduce ?? config?.reproduce,
        testCases: testCases ?? config?.testCases,
        seed: seed ?? config?.seed ?? _envSeed(),
        derandomize: derandomize ?? config?.derandomize,
        phases: phases ?? config?.phases,
        verbosity: verbosity ?? config?.verbosity,
        suppressHealthChecks:
            suppressHealthChecks ?? config?.suppressHealthChecks,
        reportMultipleFailures:
            reportMultipleFailures ?? config?.reportMultipleFailures,
        databaseKey: databaseKey ?? config?.databaseKey,
        database: database ?? config?.database,
      );
    },
    timeout: timeout ?? const Timeout(Duration(minutes: 10)),
    tags: tags,
    skip: skip,
    onPlatform: onPlatform,
    retry: retry,
  );
}

/// Property-based widget test function for Flutter.
///
/// This wraps `flutter_test`'s `testWidgets()`. The callback receives both a
/// [TestCase] for drawing random values, and a [WidgetTester] for pumping widgets.
///
/// ```dart
/// import 'package:hegeltest_flutter/hegeltest_flutter.dart';
/// import 'package:flutter_test/flutter_test.dart';
/// import 'package:flutter/material.dart';
///
/// void main() {
///   hegelFlutterWidgetTest('text widget renders correctly', (tc, tester) async {
///     final text = tc.draw(strings());
///     await tester.pumpWidget(MaterialApp(home: Text(text)));
///     expect(find.text(text), findsOneWidget);
///   });
/// }
/// ```
void hegelFlutterWidgetTest(
  String description,
  FutureOr<void> Function(TestCase tc, WidgetTester tester) body, {
  dynamic skip,
  Timeout? timeout,
  dynamic tags,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  int? retry,
  HegelConfig? config,
  int? testCases,
  int? seed,
  bool? derandomize,
  Set<Phase>? phases,
  Verbosity? verbosity,
  Set<HealthCheck>? suppressHealthChecks,
  bool? reportMultipleFailures,
  String? reproduce,
  String? databaseKey,
  String? database,
  FutureOr<void> Function()? setUpEach,
  FutureOr<void> Function()? tearDownEach,
}) {
  testWidgets(
    description,
    (tester) async {
      final lib = loadHegelLibrary();
      final runner = HegelRunner(lib);
      await runner.run(
        (tc) async {
          await body(tc, tester);
        },
        reproduceBlob: reproduce ?? config?.reproduce,
        testCases: testCases ?? config?.testCases,
        seed: seed ?? config?.seed ?? _envSeed(),
        derandomize: derandomize ?? config?.derandomize,
        phases: phases ?? config?.phases,
        verbosity: verbosity ?? config?.verbosity,
        suppressHealthChecks:
            suppressHealthChecks ?? config?.suppressHealthChecks,
        reportMultipleFailures:
            reportMultipleFailures ?? config?.reportMultipleFailures,
        databaseKey: databaseKey ?? config?.databaseKey,
        database: database ?? config?.database,
        setUpEach: setUpEach,
        tearDownEach: tearDownEach,
      );
    },
    skip: skip,
    timeout: timeout ?? const Timeout(Duration(minutes: 10)),
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
    retry: retry,
  );
}
