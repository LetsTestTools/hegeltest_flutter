import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  group('hegelFlutterLayoutSweepTest', () {
    hegelFlutterLayoutSweepTest(
      'responsive layout passes sweep across sizes and text scales',
      testCases: 10,
      sweepConfig: const LayoutSweepConfig(
        minWidth: 320,
        maxWidth: 1024,
        minHeight: 480,
        maxHeight: 1200,
        minTextScale: 0.8,
        maxTextScale: 2.0,
      ),
      builder: (tc, sample) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text('Viewport: ${sample.width} x ${sample.height}'),
                Text('Scale: ${sample.textScale}x'),
                Wrap(
                  children: List.generate(
                    5,
                    (i) => Chip(label: Text('Tag $i')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      invariant: (tc, tester, sample) async {
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        final BuildContext ctx = tester.element(find.byType(Scaffold));
        expect(Directionality.of(ctx), equals(sample.textDirection));
        expect(
          MediaQuery.of(ctx).viewInsets.bottom,
          equals(sample.viewInsetsBottom),
        );
        expect(
          MediaQuery.of(ctx).platformBrightness,
          equals(sample.brightness),
        );
        expect(
          MediaQuery.textScalerOf(ctx),
          equals(TextScaler.linear(sample.textScale)),
        );
      },
    );

    test('LayoutSweepConfig.validate rejects invalid configurations', () {
      expect(
        () => const LayoutSweepConfig(minWidth: 0).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(maxWidth: double.infinity).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(minWidth: 800, maxWidth: 400).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(
          minWidth: 320.9,
          maxWidth: 320.1,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () =>
            const LayoutSweepConfig(minHeight: 900, maxHeight: 500).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(
          minHeight: 480.8,
          maxHeight: 480.2,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(
          minTextScale: 2.5,
          maxTextScale: 1.0,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(maxTextScale: double.infinity).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(
          minTextScale: 1.004,
          maxTextScale: 1.001,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(textDirections: []).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(devicePixelRatios: [0.0]).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(
          devicePixelRatios: [double.infinity],
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(viewInsetsBottom: [-10.0]).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(
          viewInsetsBottom: [double.infinity],
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LayoutSweepConfig(brightnesses: []).validate(),
        throwsArgumentError,
      );
    });

    testWidgets('layout sweep captures RenderFlex overflow', (tester) async {
      var detectedOverflow = false;

      // Wrap a fixed 400px box inside a 300px constraint to trigger overflow
      tester.view.physicalSize = const Size(300, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(300, 500),
            textScaler: TextScaler.linear(1.0),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: Row(
                children: const [
                  SizedBox(width: 450, height: 50, child: Text('Too wide')),
                ],
              ),
            ),
          ),
        ),
      );

      final ex = tester.takeException();
      if (ex != null && ex.toString().contains('RenderFlex overflowed')) {
        detectedOverflow = true;
      }

      expect(detectedOverflow, isTrue);
    });
  });
}
