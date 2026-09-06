import 'dart:async';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest/hegeltest.dart';

/// Represents a single action performed by the monkey during a fuzzing run.
class MonkeyStep {
  /// The semantics node ID targeted by this action.
  final int nodeId;

  /// The accessibility label of the target node, or empty if none.
  final String label;

  /// The semantics action executed (e.g. tap, setText, scrollDown).
  final SemanticsAction action;

  /// The argument passed to the action, if any (such as typed text).
  final Object? argument;

  const MonkeyStep({
    required this.nodeId,
    required this.label,
    required this.action,
    this.argument,
  });

  @override
  String toString() {
    final target = label.isNotEmpty
        ? ' "$label" (id=$nodeId)'
        : ' node $nodeId';
    final argStr = argument != null ? ' with "$argument"' : '';
    return '${action.name} on$target$argStr';
  }
}

/// Exception thrown when monkey fuzzing discovers an unhandled crash or invariant failure.
class MonkeyFuzzException implements Exception {
  final List<MonkeyStep> steps;
  final dynamic cause;
  final StackTrace? stackTrace;

  MonkeyFuzzException({
    required this.steps,
    required this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Monkey fuzzing caught an error after ${steps.length} step(s):',
    );
    for (var i = 0; i < steps.length; i++) {
      buffer.writeln('  ${i + 1}. ${steps[i]}');
    }
    buffer.writeln('Cause: $cause');
    if (stackTrace != null) {
      buffer.writeln('Stack trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

class _CandidateAction {
  final SemanticsNode node;
  final SemanticsAction action;
  _CandidateAction(this.node, this.action);
}

/// The standard set of semantic actions explored by default in monkey fuzzing.
const List<SemanticsAction> kDefaultMonkeyActions = [
  SemanticsAction.tap,
  SemanticsAction.longPress,
  SemanticsAction.scrollUp,
  SemanticsAction.scrollDown,
  SemanticsAction.scrollLeft,
  SemanticsAction.scrollRight,
  SemanticsAction.increase,
  SemanticsAction.decrease,
  SemanticsAction.setText,
  SemanticsAction.dismiss,
];

/// Property-based monkey fuzzing test for Flutter widgets.
///
/// In each property iteration, [hegelFlutterMonkeyTest] creates and pumps the
/// widget returned by [createWidget], traverses Flutter's active [SemanticsOwner]
/// tree, discovers available interactive nodes and actions, and uses Hegel's
/// engine to draw and execute action sequences.
///
/// When an unhandled exception or assertion failure occurs, Hegel's engine
/// automatically shrinks the action sequence to the minimal steps to reproduce.
///
/// ```dart
/// hegelFlutterMonkeyTest(
///   'smoke-test counter app',
///   createWidget: (tc) => const CounterApp(),
///   steps: 20,
/// );
/// ```
void hegelFlutterMonkeyTest(
  String description, {
  required Widget Function(TestCase tc) createWidget,
  int steps = 15,
  Duration pumpDuration = const Duration(milliseconds: 50),
  List<SemanticsAction>? allowedActions,
  FutureOr<void> Function(TestCase tc, WidgetTester tester)? invariant,
  FutureOr<void> Function(TestCase tc, WidgetTester tester, MonkeyStep step)?
  stepInvariant,
  dynamic skip,
  Timeout? timeout,
  dynamic tags,
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
      final lib = loadHegelLibrary();
      final runner = HegelRunner(lib);

      await runner.run(
        (tc) async {
          final widget = createWidget(tc);
          await tester.pumpWidget(widget);

          final owner = tester.binding.rootPipelineOwner.semanticsOwner;
          if (owner == null) {
            throw StateError(
              'SemanticsOwner is not available. Ensure semanticsEnabled is true.',
            );
          }

          final effectiveAllowedActions =
              allowedActions ?? kDefaultMonkeyActions;
          final stepHistory = <MonkeyStep>[];

          for (var i = 0; i < steps; i++) {
            final candidates = _collectCandidates(
              owner.rootSemanticsNode,
              effectiveAllowedActions,
            );

            if (candidates.isEmpty) {
              break;
            }

            final choice = tc.draw(
              integers(min: 0, max: candidates.length - 1),
              label: 'step_${i + 1}_action_index',
            );
            final candidate = candidates[choice];
            final node = candidate.node;
            final action = candidate.action;
            final label = node.getSemanticsData().label;

            Object? actionArg;
            if (action == SemanticsAction.setText) {
              actionArg = tc.draw(text(), label: 'step_${i + 1}_text_value');
              owner.performAction(node.id, action, actionArg);
            } else {
              owner.performAction(node.id, action);
            }

            final step = MonkeyStep(
              nodeId: node.id,
              label: label,
              action: action,
              argument: actionArg,
            );
            stepHistory.add(step);

            await tester.pump(pumpDuration);

            final dynamic caughtEx = tester.takeException();
            if (caughtEx != null) {
              throw MonkeyFuzzException(steps: stepHistory, cause: caughtEx);
            }

            if (stepInvariant != null) {
              try {
                await stepInvariant(tc, tester, step);
              } catch (e, st) {
                throw MonkeyFuzzException(
                  steps: stepHistory,
                  cause: e,
                  stackTrace: st,
                );
              }
            }
          }

          if (invariant != null) {
            try {
              await invariant(tc, tester);
            } catch (e, st) {
              throw MonkeyFuzzException(
                steps: stepHistory,
                cause: e,
                stackTrace: st,
              );
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
        databaseKey: databaseKey ?? config?.databaseKey ?? description,
        database: database ?? config?.database,
        databasePath: databasePath ?? config?.databasePath,
        setUpEach: setUpEach,
        tearDownEach: tearDownEach,
      );
    },
    skip: skip,
    timeout: timeout ?? const Timeout(Duration(minutes: 10)),
    semanticsEnabled: true,
    variant: variant,
    tags: tags,
    retry: retry,
  );
}

List<_CandidateAction> _collectCandidates(
  SemanticsNode? root,
  List<SemanticsAction> allowedActions,
) {
  if (root == null) return const [];
  final candidates = <_CandidateAction>[];

  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && !node.isInvisible) {
      final data = node.getSemanticsData();
      for (final action in allowedActions) {
        if (data.hasAction(action)) {
          candidates.add(_CandidateAction(node, action));
        }
      }
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return candidates;
}

int? _envSeed() {
  final raw = Platform.environment['HEGEL_SEED'];
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
}
