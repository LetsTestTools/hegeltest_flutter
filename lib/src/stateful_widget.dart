import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest/hegeltest.dart';

import 'env.dart';
import 'flutter_runner.dart';

/// A rule executed during stateful widget property testing.
///
/// Mirrors [StateRule], providing both the [WidgetTester] for driving UI
/// interactions and the [TestCase] for drawing inputs or recording notes.
class WidgetStateRule {
  /// Human-readable name, recorded in diagnostic notes and failure reports.
  final String name;

  /// Optional precondition evaluated before the engine selects this rule.
  final bool Function()? precondition;

  /// Relative selection weight for this rule (must be finite and > 0).
  final double weight;

  /// Rule action body receiving both [WidgetTester] and [TestCase].
  final FutureOr<void> Function(WidgetTester tester, TestCase tc) execute;

  /// Creates a stateful widget rule.
  WidgetStateRule(
    this.name, {
    this.precondition,
    this.weight = 1.0,
    required this.execute,
  }) {
    if (!weight.isFinite || weight <= 0) {
      throw ArgumentError.value(weight, 'weight', 'must be finite and > 0');
    }
  }
}

/// An invariant checked during stateful widget property testing.
class WidgetStateInvariant {
  /// Human-readable name used in diagnostics.
  final String name;

  /// Whether to check this invariant after every step (`true`) or sample (`false`).
  final bool alwaysCheck;

  /// Invariant assertion receiving both [WidgetTester] and [TestCase].
  final FutureOr<void> Function(WidgetTester tester, TestCase tc) check;

  /// Creates a stateful widget invariant.
  const WidgetStateInvariant(
    this.name, {
    this.alwaysCheck = true,
    required this.check,
  });
}

/// Base class for stateful property-based Flutter widget tests.
///
/// Subclass this to model sequences of user/widget interactions with [rules]
/// and verify UI + model consistency with [invariants].
abstract class WidgetStateMachine {
  _WidgetStateMachineAdapter? _adapter;

  /// Builds the root widget pumped once before rules begin executing.
  Widget buildInitialWidget(TestCase tc);

  /// Operations that can be executed against the mounted widget tree.
  List<WidgetStateRule> get rules;

  /// Invariants verified at initial state, between rounds, and at final state.
  List<WidgetStateInvariant> get invariants => const [];

  /// Target number of steps per test case (must be >= 1). Defaults to 50.
  int get stepCount => 50;

  /// Called before pumping [buildInitialWidget] on each test case iteration.
  FutureOr<void> setUp(WidgetTester tester) {}

  /// Called after each test case iteration (including failing ones) for cleanup.
  FutureOr<void> tearDown(WidgetTester tester) {}

  /// Creates and registers a [Pool] for passing values between rules.
  ///
  /// Must be called inside [setUp].
  Pool<T> createPool<T>() {
    final adapter = _adapter;
    if (adapter == null) {
      throw StateError(
        'WidgetStateMachine.createPool() must be called during setUp().',
      );
    }
    return adapter.createPool<T>();
  }
}

class _WidgetStateMachineAdapter extends StateMachine {
  final WidgetStateMachine _machine;
  final WidgetTester _tester;
  int _step = 0;

  _WidgetStateMachineAdapter(this._machine, this._tester);

  @override
  int get stepCount => _machine.stepCount;

  @override
  List<StateRule> get rules => [
    for (final rule in _machine.rules)
      StateRule(
        rule.name,
        precondition: rule.precondition,
        weight: rule.weight,
        execute: (tc) async {
          _step++;
          tc.note('step $_step: ${rule.name}');
          await rule.execute(_tester, tc);
          _rethrowPendingWidgetException(_tester);
        },
      ),
  ];

  @override
  List<StateInvariant> get invariants => [
    for (final inv in _machine.invariants)
      StateInvariant(
        inv.name,
        alwaysCheck: inv.alwaysCheck,
        check: (tc) async {
          await inv.check(_tester, tc);
          _rethrowPendingWidgetException(_tester);
        },
      ),
  ];
}

Never _throwCapturedException(Object caughtEx, [StackTrace? fallbackStack]) {
  if (caughtEx is Error && caughtEx.stackTrace != null) {
    Error.throwWithStackTrace(caughtEx, caughtEx.stackTrace!);
  }
  if (fallbackStack != null) {
    Error.throwWithStackTrace(caughtEx, fallbackStack);
  }
  throw caughtEx;
}

void _rethrowPendingWidgetException(WidgetTester tester) {
  final dynamic caughtEx = tester.takeException();
  if (caughtEx != null) {
    _throwCapturedException(caughtEx as Object);
  }
}

void _drainAndLogPendingExceptions(WidgetTester tester, String context) {
  while (true) {
    final dynamic extraEx = tester.takeException();
    if (extraEx == null) break;
    stderr.writeln('[hegeltest_flutter] Extra exception ($context): $extraEx');
  }
}

Future<void> _runStatefulWidgetIteration(
  TestCase tc,
  WidgetTester tester,
  WidgetStateMachine Function() create,
) async {
  final machine = create();
  final adapter = _WidgetStateMachineAdapter(machine, tester);
  machine._adapter = adapter;

  var bodyThrew = false;
  Object? cleanupError;
  StackTrace? cleanupStack;

  void recordCleanupError(
    Object error, [
    StackTrace? stackTrace,
    String context = 'cleanup',
  ]) {
    if (!bodyThrew && cleanupError == null) {
      cleanupError = error;
      cleanupStack = stackTrace ?? (error is Error ? error.stackTrace : null);
    } else {
      stderr.writeln('[hegeltest_flutter] $context threw: $error');
      if (stackTrace != null) {
        stderr.writeln(stackTrace);
      }
    }
  }

  try {
    await machine.setUp(tester);
    _rethrowPendingWidgetException(tester);
    await tester.pumpWidget(
      KeyedSubtree(key: UniqueKey(), child: machine.buildInitialWidget(tc)),
    );
    _rethrowPendingWidgetException(tester);
    await runStateMachine(tc, adapter);
  } catch (_) {
    bodyThrew = true;
    rethrow;
  } finally {
    if (bodyThrew) {
      _drainAndLogPendingExceptions(tester, 'body');
    } else {
      final dynamic bodyEx = tester.takeException();
      if (bodyEx != null) {
        recordCleanupError(bodyEx as Object, null, 'body pending');
      }
    }

    try {
      await machine.tearDown(tester);
      final dynamic tearDownEx = tester.takeException();
      if (tearDownEx != null) {
        recordCleanupError(tearDownEx as Object, null, 'tearDown');
        _drainAndLogPendingExceptions(tester, 'tearDown');
      }
    } catch (e, st) {
      recordCleanupError(e, st, 'tearDown');
      _drainAndLogPendingExceptions(tester, 'tearDown');
    }

    try {
      await tester.pumpWidget(SizedBox.shrink(key: UniqueKey()));
      final dynamic disposeEx = tester.takeException();
      if (disposeEx != null) {
        recordCleanupError(disposeEx as Object, null, 'widget dispose');
        _drainAndLogPendingExceptions(tester, 'widget dispose');
      }
    } catch (e, st) {
      recordCleanupError(e, st, 'widget dispose');
      _drainAndLogPendingExceptions(tester, 'widget dispose');
    } finally {
      machine._adapter = null;
    }

    if (!bodyThrew && cleanupError != null) {
      _throwCapturedException(cleanupError!, cleanupStack);
    }
  }
}

/// Runs a stateful property-based Flutter widget test inside `testWidgets`.
///
/// For each iteration (and shrink attempt), constructs a fresh
/// [WidgetStateMachine] via [create], resets the widget tree, pumps
/// [WidgetStateMachine.buildInitialWidget], and executes engine-guided rules
/// and invariants with step logging via `tc.note()`.
void hegelFlutterStatefulWidgetTest(
  String description,
  WidgetStateMachine Function() create, {
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
  bool? database,
  String? databasePath,
  FutureOr<void> Function()? setUpEach,
  FutureOr<void> Function()? tearDownEach,
}) {
  testWidgets(
    description,
    (tester) async {
      final runner = HegelRunner();
      await runner.run(
        (tc) => _runStatefulWidgetIteration(tc, tester, create),
        reproduceBlob: reproduce ?? config?.reproduce,
        testCases: testCases ?? config?.testCases,
        seed: seed ?? config?.seed ?? envSeed(),
        derandomize: derandomize ?? config?.derandomize,
        phases: phases ?? config?.phases,
        verbosity: verbosity ?? config?.verbosity,
        suppressHealthChecks:
            suppressHealthChecks ?? config?.suppressHealthChecks,
        reportMultipleFailures:
            reportMultipleFailures ?? config?.reportMultipleFailures,
        databaseKey: databaseKey ?? config?.databaseKey ?? description,
        database: database ?? config?.database,
        databasePath: databasePath ?? config?.databasePath,
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

/// Standalone runner for stateful widget property tests using an existing
/// [WidgetTester], returning a [RunResult] instead of throwing.
Future<RunResult> runHegelFlutterStatefulWidgetTest(
  WidgetTester tester,
  WidgetStateMachine Function() create, {
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
  bool? database,
  String? databasePath,
  FutureOr<void> Function()? setUpEach,
  FutureOr<void> Function()? tearDownEach,
}) {
  return runHegelFlutterTest(
    (tc) => _runStatefulWidgetIteration(tc, tester, create),
    config: config,
    testCases: testCases,
    seed: seed,
    derandomize: derandomize,
    phases: phases,
    verbosity: verbosity,
    suppressHealthChecks: suppressHealthChecks,
    reportMultipleFailures: reportMultipleFailures,
    reproduce: reproduce,
    databaseKey:
        databaseKey ??
        config?.databaseKey ??
        'runHegelFlutterStatefulWidgetTest',
    database: database,
    databasePath: databasePath,
    setUpEach: setUpEach,
    tearDownEach: tearDownEach,
  );
}
