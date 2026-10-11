import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest/hegeltest.dart';

import 'env.dart';

/// Configuration bounds and options for [hegelFlutterLayoutSweepTest].
class LayoutSweepConfig {
  /// Minimum viewport width in logical pixels. Default: 320.0.
  final double minWidth;

  /// Maximum viewport width in logical pixels. Default: 1440.0.
  final double maxWidth;

  /// Minimum viewport height in logical pixels. Default: 480.0.
  final double minHeight;

  /// Maximum viewport height in logical pixels. Default: 2560.0.
  final double maxHeight;

  /// Minimum text scaling factor. Default: 0.8.
  final double minTextScale;

  /// Maximum text scaling factor. Default: 3.0.
  final double maxTextScale;

  /// Text directions to sample. Default: [TextDirection.ltr, TextDirection.rtl].
  final List<TextDirection> textDirections;

  /// Device pixel ratios to sample. Default: [1.0, 2.0, 3.0].
  final List<double> devicePixelRatios;

  /// Bottom view insets to sample (e.g. keyboard open / closed). Default: [0.0, 300.0].
  final List<double> viewInsetsBottom;

  /// Brightnesses to sample. Default: [Brightness.light, Brightness.dark].
  final List<Brightness> brightnesses;

  const LayoutSweepConfig({
    this.minWidth = 320.0,
    this.maxWidth = 1440.0,
    this.minHeight = 480.0,
    this.maxHeight = 2560.0,
    this.minTextScale = 0.8,
    this.maxTextScale = 3.0,
    this.textDirections = const [TextDirection.ltr, TextDirection.rtl],
    this.devicePixelRatios = const [1.0, 2.0, 3.0],
    this.viewInsetsBottom = const [0.0, 300.0],
    this.brightnesses = const [Brightness.light, Brightness.dark],
  });

  /// Validates that all sweep bounds and option lists are well-formed.
  ///
  /// Throws [ArgumentError] if any bound is non-positive, non-finite, inverted, or empty.
  void validate() {
    if (minWidth <= 0 || !minWidth.isFinite) {
      throw ArgumentError.value(
        minWidth,
        'minWidth',
        'must be positive and finite',
      );
    }
    if (maxWidth <= 0 || !maxWidth.isFinite) {
      throw ArgumentError.value(
        maxWidth,
        'maxWidth',
        'must be positive and finite',
      );
    }
    if (minWidth > maxWidth || minWidth.ceil() > maxWidth.floor()) {
      throw ArgumentError(
        'LayoutSweepConfig: minWidth ($minWidth) must be <= maxWidth ($maxWidth) '
        'and span at least one integer logical pixel',
      );
    }
    if (minHeight <= 0 || !minHeight.isFinite) {
      throw ArgumentError.value(
        minHeight,
        'minHeight',
        'must be positive and finite',
      );
    }
    if (maxHeight <= 0 || !maxHeight.isFinite) {
      throw ArgumentError.value(
        maxHeight,
        'maxHeight',
        'must be positive and finite',
      );
    }
    if (minHeight > maxHeight || minHeight.ceil() > maxHeight.floor()) {
      throw ArgumentError(
        'LayoutSweepConfig: minHeight ($minHeight) must be <= maxHeight ($maxHeight) '
        'and span at least one integer logical pixel',
      );
    }
    if (minTextScale <= 0 || !minTextScale.isFinite) {
      throw ArgumentError.value(
        minTextScale,
        'minTextScale',
        'must be positive and finite',
      );
    }
    if (maxTextScale <= 0 || !maxTextScale.isFinite) {
      throw ArgumentError.value(
        maxTextScale,
        'maxTextScale',
        'must be positive and finite',
      );
    }
    if (minTextScale > maxTextScale ||
        (minTextScale * 100).round() > (maxTextScale * 100).round()) {
      throw ArgumentError(
        'LayoutSweepConfig: minTextScale ($minTextScale) must be <= maxTextScale ($maxTextScale)',
      );
    }
    if (textDirections.isEmpty) {
      throw ArgumentError.value(
        textDirections,
        'textDirections',
        'must not be empty',
      );
    }
    if (devicePixelRatios.isEmpty ||
        devicePixelRatios.any((dpr) => dpr <= 0 || !dpr.isFinite)) {
      throw ArgumentError.value(
        devicePixelRatios,
        'devicePixelRatios',
        'must be non-empty with positive finite values',
      );
    }
    if (viewInsetsBottom.isEmpty ||
        viewInsetsBottom.any((inset) => inset < 0 || !inset.isFinite)) {
      throw ArgumentError.value(
        viewInsetsBottom,
        'viewInsetsBottom',
        'must be non-empty with non-negative finite values',
      );
    }
    if (brightnesses.isEmpty) {
      throw ArgumentError.value(
        brightnesses,
        'brightnesses',
        'must not be empty',
      );
    }
  }
}

/// The concrete viewport and accessibility parameters drawn for a test iteration.
class LayoutSample {
  final double width;
  final double height;
  final double textScale;
  final TextDirection textDirection;
  final double devicePixelRatio;
  final double viewInsetsBottom;
  final Brightness brightness;

  const LayoutSample({
    required this.width,
    required this.height,
    required this.textScale,
    required this.textDirection,
    required this.devicePixelRatio,
    required this.viewInsetsBottom,
    required this.brightness,
  });

  @override
  String toString() {
    return 'LayoutSample(${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)}, '
        'textScale: ${textScale.toStringAsFixed(2)}x, '
        'direction: ${textDirection.name}, '
        'dpr: $devicePixelRatio, '
        'keyboard: ${viewInsetsBottom > 0 ? "up" : "down"}, '
        'brightness: ${brightness.name})';
  }
}

/// Exception thrown when a layout sweep detects a RenderFlex overflow or layout failure.
class LayoutOverflowException implements Exception {
  final LayoutSample sample;
  final dynamic cause;

  LayoutOverflowException({required this.sample, required this.cause});

  @override
  String toString() {
    return 'Layout invariant violated:\n'
        '  Configuration: $sample\n'
        '  Error: $cause';
  }
}

/// Property-based layout sweep test that verifies widgets across viewport sizes,
/// text scalers, screen densities, and orientations.
///
/// In each property iteration, [hegelFlutterLayoutSweepTest] draws dynamic display
/// parameters, sets [WidgetTester.view.physicalSize], wraps the widget in
/// [MediaQuery] and [Directionality], pumps the widget, and asserts zero
/// `RenderFlex overflowed` or framework layout errors.
///
/// When an overflow occurs, Hegel's engine automatically shrinks the viewport
/// dimensions and font scale to find the minimal boundary condition.
///
/// ```dart
/// hegelFlutterLayoutSweepTest(
///   'user profile card does not overflow',
///   builder: (tc, sample) => const UserProfileCard(),
/// );
/// ```
void hegelFlutterLayoutSweepTest(
  String description, {
  required Widget Function(TestCase tc, LayoutSample sample) builder,
  LayoutSweepConfig sweepConfig = const LayoutSweepConfig(),
  FutureOr<void> Function(
    TestCase tc,
    WidgetTester tester,
    LayoutSample sample,
  )?
  invariant,
  bool wrapWithApp = true,
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
  sweepConfig.validate();

  testWidgets(
    description,
    (tester) async {
      ensureFlutterNativeAssets();
      final lib = loadHegelLibrary();
      final runner = HegelRunner(lib);

      void resetViewOverrides() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      }

      addTearDown(resetViewOverrides);

      await runner.run(
        (tc) async {
          final width = tc
              .draw(
                integers(
                  min: sweepConfig.minWidth.ceil(),
                  max: sweepConfig.maxWidth.floor(),
                ),
                label: 'viewport_width',
              )
              .toDouble();

          final height = tc
              .draw(
                integers(
                  min: sweepConfig.minHeight.ceil(),
                  max: sweepConfig.maxHeight.floor(),
                ),
                label: 'viewport_height',
              )
              .toDouble();

          final textScaleInt = tc.draw(
            integers(
              min: (sweepConfig.minTextScale * 100).round(),
              max: (sweepConfig.maxTextScale * 100).round(),
            ),
            label: 'text_scale_percent',
          );
          final textScale = textScaleInt / 100.0;

          final dirIdx = tc.draw(
            integers(min: 0, max: sweepConfig.textDirections.length - 1),
            label: 'direction_index',
          );
          final textDirection = sweepConfig.textDirections[dirIdx];

          final dprIdx = tc.draw(
            integers(min: 0, max: sweepConfig.devicePixelRatios.length - 1),
            label: 'dpr_index',
          );
          final dpr = sweepConfig.devicePixelRatios[dprIdx];

          final kbIdx = tc.draw(
            integers(min: 0, max: sweepConfig.viewInsetsBottom.length - 1),
            label: 'keyboard_index',
          );
          final keyboardBottom = sweepConfig.viewInsetsBottom[kbIdx];

          final brightIdx = tc.draw(
            integers(min: 0, max: sweepConfig.brightnesses.length - 1),
            label: 'brightness_index',
          );
          final brightness = sweepConfig.brightnesses[brightIdx];

          final sample = LayoutSample(
            width: width,
            height: height,
            textScale: textScale,
            textDirection: textDirection,
            devicePixelRatio: dpr,
            viewInsetsBottom: keyboardBottom,
            brightness: brightness,
          );

          tester.view.physicalSize = Size(width * dpr, height * dpr);
          tester.view.devicePixelRatio = dpr;
          tester.view.viewInsets = FakeViewPadding(
            bottom: keyboardBottom * dpr,
          );
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          tester.platformDispatcher.platformBrightnessTestValue = brightness;

          final mediaQueryData = MediaQueryData(
            size: Size(width, height),
            devicePixelRatio: dpr,
            textScaler: TextScaler.linear(textScale),
            platformBrightness: brightness,
            viewInsets: EdgeInsets.only(bottom: keyboardBottom),
          );

          final widget = builder(tc, sample);

          final Widget root;
          if (wrapWithApp && widget is! MaterialApp && widget is! WidgetsApp) {
            root = MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(brightness: brightness),
              builder: (context, child) {
                return MediaQuery(
                  data: mediaQueryData,
                  child: Directionality(
                    textDirection: textDirection,
                    child: child!,
                  ),
                );
              },
              home: Material(type: MaterialType.transparency, child: widget),
            );
          } else {
            root = MediaQuery(
              data: mediaQueryData,
              child: Directionality(
                textDirection: textDirection,
                child: widget,
              ),
            );
          }

          await tester.pumpWidget(root);

          final dynamic caughtEx = tester.takeException();
          if (caughtEx != null) {
            throw LayoutOverflowException(sample: sample, cause: caughtEx);
          }

          if (invariant != null) {
            await invariant(tc, tester, sample);
          }
        },
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
        tearDownEach: () async {
          resetViewOverrides();
          if (tearDownEach != null) {
            await tearDownEach();
          }
        },
      );
    },
    skip: skip,
    timeout: timeout ?? const Timeout(Duration(minutes: 10)),
    variant: variant,
    tags: tags,
    retry: retry,
  );
}
