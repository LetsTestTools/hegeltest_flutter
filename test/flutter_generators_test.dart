import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hegeltest_flutter/generators.dart' as gen;
import 'package:hegeltest_flutter/hegeltest_flutter.dart';

void main() {
  group('Flutter value generators', () {
    hegelFlutterTest('colors() generates valid ARGB and opaque colors', (tc) {
      final argb = tc.draw(gen.colors());
      expect(argb, isA<Color>());

      final opaque = tc.draw(gen.colors(allowAlpha: false));
      expect((opaque.toARGB32() >> 24) & 0xff, equals(255));
    });

    hegelFlutterTest('offsets() respects coordinate bounds', (tc) {
      final o = tc.draw(
        gen.offsets(minDx: -10.0, maxDx: 25.0, minDy: 5.0, maxDy: 50.0),
      );
      expect(o.dx, inInclusiveRange(-10.0, 25.0));
      expect(o.dy, inInclusiveRange(5.0, 50.0));
    });

    hegelFlutterTest('sizes() generates non-negative sizes within bounds', (
      tc,
    ) {
      final s = tc.draw(
        gen.sizes(
          minWidth: 10.0,
          maxWidth: 200.0,
          minHeight: 20.0,
          maxHeight: 300.0,
        ),
      );
      expect(s.width, inInclusiveRange(10.0, 200.0));
      expect(s.height, inInclusiveRange(20.0, 300.0));
    });

    hegelFlutterTest('edgeInsets() supports arbitrary and symmetric insets', (
      tc,
    ) {
      final arbitrary = tc.draw(gen.edgeInsets(min: 2.0, max: 32.0));
      expect(arbitrary.isNonNegative, isTrue);
      expect(arbitrary.left, inInclusiveRange(2.0, 32.0));
      expect(arbitrary.top, inInclusiveRange(2.0, 32.0));
      expect(arbitrary.right, inInclusiveRange(2.0, 32.0));
      expect(arbitrary.bottom, inInclusiveRange(2.0, 32.0));

      final sym = tc.draw(
        gen.edgeInsets(min: 4.0, max: 16.0, symmetricOnly: true),
      );
      expect(sym.left, equals(sym.right));
      expect(sym.top, equals(sym.bottom));
      expect(sym.left, inInclusiveRange(4.0, 16.0));
      expect(sym.top, inInclusiveRange(4.0, 16.0));
    });

    hegelFlutterTest(
      'boxConstraints() always generates normalized constraints',
      (tc) {
        final bounded = tc.draw(
          gen.boxConstraints(
            minWidth: 10.0,
            maxWidth: 400.0,
            minHeight: 20.0,
            maxHeight: 500.0,
          ),
        );
        expect(bounded.isNormalized, isTrue);
        expect(bounded.minWidth, inInclusiveRange(10.0, 400.0));
        expect(bounded.maxWidth, inInclusiveRange(bounded.minWidth, 400.0));
        expect(bounded.minHeight, inInclusiveRange(20.0, 500.0));
        expect(bounded.maxHeight, inInclusiveRange(bounded.minHeight, 500.0));
        expect(bounded.hasBoundedWidth, isTrue);
        expect(bounded.hasBoundedHeight, isTrue);
      },
    );

    test(
      'boxConstraints(allowUnbounded: true) can emit unbounded dimensions',
      () async {
        var sawUnbounded = false;
        final res = await runHegelFlutterTest(
          (tc) {
            final c = tc.draw(gen.boxConstraints(allowUnbounded: true));
            expect(c.isNormalized, isTrue);
            if (!c.hasBoundedWidth || !c.hasBoundedHeight) {
              sawUnbounded = true;
            }
          },
          testCases: 80,
          database: false,
        );
        expect(res.status, equals(RunStatus.passed));
        expect(sawUnbounded, isTrue);
      },
    );

    hegelFlutterTest('borderRadii() respects bounds and circularOnly', (tc) {
      final anyRadius = tc.draw(
        gen.borderRadii(minRadius: 1.0, maxRadius: 24.0),
      );
      expect(anyRadius.topLeft.x, inInclusiveRange(1.0, 24.0));
      expect(anyRadius.topRight.x, inInclusiveRange(1.0, 24.0));
      expect(anyRadius.bottomLeft.x, inInclusiveRange(1.0, 24.0));
      expect(anyRadius.bottomRight.x, inInclusiveRange(1.0, 24.0));

      final circ = tc.draw(
        gen.borderRadii(minRadius: 2.0, maxRadius: 12.0, circularOnly: true),
      );
      expect(circ.topLeft, equals(circ.topRight));
      expect(circ.topLeft, equals(circ.bottomLeft));
      expect(circ.topLeft, equals(circ.bottomRight));
      expect(circ.topLeft.x, inInclusiveRange(2.0, 12.0));
    });

    hegelFlutterTest('locales(), directions, brightnesses, themeModes work', (
      tc,
    ) {
      final loc = tc.draw(gen.locales());
      expect(loc.languageCode, isNotEmpty);

      final custom = tc.draw(gen.locales([const Locale('en', 'GB')]));
      expect(custom, equals(const Locale('en', 'GB')));

      final dir = tc.draw(gen.textDirections());
      expect(TextDirection.values, contains(dir));

      final br = tc.draw(gen.brightnesses());
      expect(Brightness.values, contains(br));

      final mode = tc.draw(gen.themeModes());
      expect(ThemeMode.values, contains(mode));
    });

    hegelFlutterTest('textScalers() respects scale factor bounds', (tc) {
      final scaler = tc.draw(gen.textScalers(minScale: 0.75, maxScale: 2.25));
      expect(scaler.scale(1.0), inInclusiveRange(0.75, 2.25));
    });

    hegelFlutterTest('alignments() generates in-range alignments', (tc) {
      final align = tc.draw(gen.alignments());
      expect(align.x, inInclusiveRange(-1.0, 1.0));
      expect(align.y, inInclusiveRange(-1.0, 1.0));
    });

    test('validates bounds eagerly with ArgumentError', () {
      expect(() => gen.offsets(minDx: 10.0, maxDx: 5.0), throwsArgumentError);
      expect(() => gen.offsets(minDx: double.nan), throwsArgumentError);
      expect(() => gen.offsets(maxDy: double.infinity), throwsArgumentError);

      expect(() => gen.sizes(minWidth: -1.0), throwsArgumentError);
      expect(
        () => gen.sizes(minHeight: 50.0, maxHeight: 10.0),
        throwsArgumentError,
      );

      expect(() => gen.edgeInsets(min: -0.1), throwsArgumentError);
      expect(() => gen.edgeInsets(min: 20.0, max: 10.0), throwsArgumentError);

      expect(() => gen.boxConstraints(minWidth: -1.0), throwsArgumentError);
      expect(
        () => gen.boxConstraints(minWidth: 100.0, maxWidth: 50.0),
        throwsArgumentError,
      );
      expect(
        () => gen.boxConstraints(maxWidth: double.infinity),
        throwsArgumentError,
      );

      expect(() => gen.borderRadii(minRadius: -2.0), throwsArgumentError);
      expect(
        () => gen.borderRadii(minRadius: 10.0, maxRadius: 5.0),
        throwsArgumentError,
      );

      expect(() => gen.locales([]), throwsArgumentError);

      expect(() => gen.textScalers(minScale: 0.0), throwsArgumentError);
      expect(() => gen.textScalers(minScale: -1.0), throwsArgumentError);
      expect(
        () => gen.textScalers(minScale: 2.0, maxScale: 1.0),
        throwsArgumentError,
      );
      expect(
        () => gen.textScalers(maxScale: double.infinity),
        throwsArgumentError,
      );
    });
  });
}
