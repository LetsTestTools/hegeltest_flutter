import 'package:flutter/material.dart';
import 'package:hegeltest/hegeltest.dart';

const List<Locale> _defaultLocales = [
  Locale('en', 'US'),
  Locale('ar', 'SA'),
  Locale('he', 'IL'),
  Locale('de', 'DE'),
  Locale('ja', 'JP'),
  Locale('zh', 'CN'),
  Locale('hi', 'IN'),
  Locale('fr', 'FR'),
  Locale('es', 'ES'),
];

const List<Alignment> _presetAlignments = [
  Alignment.topLeft,
  Alignment.topCenter,
  Alignment.topRight,
  Alignment.centerLeft,
  Alignment.center,
  Alignment.centerRight,
  Alignment.bottomLeft,
  Alignment.bottomCenter,
  Alignment.bottomRight,
];

void _validateRange(
  double min,
  double max,
  String fnName, {
  String minLabel = 'min',
  String maxLabel = 'max',
  bool allowUnboundedMax = false,
  bool nonNegative = false,
  bool positive = false,
}) {
  if (min.isNaN || !min.isFinite) {
    throw ArgumentError.value(min, minLabel, '$fnName: must be finite');
  }
  if (max.isNaN || (!allowUnboundedMax && !max.isFinite)) {
    throw ArgumentError.value(
      max,
      maxLabel,
      '$fnName: must be ${allowUnboundedMax ? "finite or +infinity" : "finite"}',
    );
  }
  if (max == double.negativeInfinity) {
    throw ArgumentError.value(
      max,
      maxLabel,
      '$fnName: must not be negative infinity',
    );
  }
  if (positive && min <= 0) {
    throw ArgumentError.value(min, minLabel, '$fnName: must be > 0');
  } else if (nonNegative && min < 0) {
    throw ArgumentError.value(min, minLabel, '$fnName: must be >= 0');
  }
  if (min > max) {
    throw ArgumentError(
      '$fnName: $minLabel ($min) must be <= $maxLabel ($max)',
    );
  }
}

Generator<double> _finiteDoubles(double min, double max) =>
    doubles(min: min, max: max, allowNan: false, allowInfinity: false);

/// Generates arbitrary [Color] values across RGB channels (and alpha if [allowAlpha] is `true`).
Generator<Color> colors({bool allowAlpha = true}) {
  final byte = integers(min: 0, max: 255);
  return Generator.composite<Color>((tc) {
    final a = allowAlpha ? tc.draw(byte, label: 'alpha') : 255;
    final r = tc.draw(byte, label: 'red');
    final g = tc.draw(byte, label: 'green');
    final b = tc.draw(byte, label: 'blue');
    return Color.fromARGB(a, r, g, b);
  });
}

/// Generates 2D [Offset] values within the given finite coordinate bounds.
Generator<Offset> offsets({
  double minDx = -1000.0,
  double maxDx = 1000.0,
  double minDy = -1000.0,
  double maxDy = 1000.0,
}) {
  _validateRange(minDx, maxDx, 'offsets', minLabel: 'minDx', maxLabel: 'maxDx');
  _validateRange(minDy, maxDy, 'offsets', minLabel: 'minDy', maxLabel: 'maxDy');
  final dxGen = _finiteDoubles(minDx, maxDx);
  final dyGen = _finiteDoubles(minDy, maxDy);
  return Generator.composite<Offset>((tc) {
    return Offset(tc.draw(dxGen, label: 'dx'), tc.draw(dyGen, label: 'dy'));
  });
}

/// Generates non-negative [Size] values within the given bounds.
Generator<Size> sizes({
  double minWidth = 0.0,
  double maxWidth = 2000.0,
  double minHeight = 0.0,
  double maxHeight = 2000.0,
}) {
  _validateRange(
    minWidth,
    maxWidth,
    'sizes',
    minLabel: 'minWidth',
    maxLabel: 'maxWidth',
    nonNegative: true,
  );
  _validateRange(
    minHeight,
    maxHeight,
    'sizes',
    minLabel: 'minHeight',
    maxLabel: 'maxHeight',
    nonNegative: true,
  );
  final wGen = _finiteDoubles(minWidth, maxWidth);
  final hGen = _finiteDoubles(minHeight, maxHeight);
  return Generator.composite<Size>((tc) {
    return Size(tc.draw(wGen, label: 'width'), tc.draw(hGen, label: 'height'));
  });
}

/// Generates non-negative [EdgeInsets] values.
///
/// When [symmetricOnly] is `true`, uses [EdgeInsets.symmetric].
Generator<EdgeInsets> edgeInsets({
  double min = 0.0,
  double max = 100.0,
  bool symmetricOnly = false,
}) {
  _validateRange(min, max, 'edgeInsets', nonNegative: true);
  final edgeGen = _finiteDoubles(min, max);
  return Generator.composite<EdgeInsets>((tc) {
    if (symmetricOnly) {
      return EdgeInsets.symmetric(
        horizontal: tc.draw(edgeGen, label: 'horizontal'),
        vertical: tc.draw(edgeGen, label: 'vertical'),
      );
    }
    return EdgeInsets.fromLTRB(
      tc.draw(edgeGen, label: 'left'),
      tc.draw(edgeGen, label: 'top'),
      tc.draw(edgeGen, label: 'right'),
      tc.draw(edgeGen, label: 'bottom'),
    );
  });
}

/// Generates normalized [BoxConstraints] where `minWidth <= maxWidth` and `minHeight <= maxHeight`.
///
/// Set [allowUnbounded] to `true` to also generate infinite upper bounds (`double.infinity`).
Generator<BoxConstraints> boxConstraints({
  double minWidth = 0.0,
  double maxWidth = 2000.0,
  double minHeight = 0.0,
  double maxHeight = 2000.0,
  bool allowUnbounded = false,
}) {
  _validateRange(
    minWidth,
    maxWidth,
    'boxConstraints',
    minLabel: 'minWidth',
    maxLabel: 'maxWidth',
    allowUnboundedMax: allowUnbounded,
    nonNegative: true,
  );
  _validateRange(
    minHeight,
    maxHeight,
    'boxConstraints',
    minLabel: 'minHeight',
    maxLabel: 'maxHeight',
    allowUnboundedMax: allowUnbounded,
    nonNegative: true,
  );

  final finiteMaxW = maxWidth.isFinite
      ? maxWidth
      : (minWidth > 2000.0 ? minWidth : 2000.0);
  final finiteMaxH = maxHeight.isFinite
      ? maxHeight
      : (minHeight > 2000.0 ? minHeight : 2000.0);

  return Generator.composite<BoxConstraints>((tc) {
    final minW = tc.draw(_finiteDoubles(minWidth, finiteMaxW), label: 'minW');
    final double maxW;
    if (allowUnbounded && tc.draw(booleans(p: 0.15), label: 'unbounded_w')) {
      maxW = double.infinity;
    } else {
      maxW = tc.draw(_finiteDoubles(minW, finiteMaxW), label: 'maxW');
    }

    final minH = tc.draw(_finiteDoubles(minHeight, finiteMaxH), label: 'minH');
    final double maxH;
    if (allowUnbounded && tc.draw(booleans(p: 0.15), label: 'unbounded_h')) {
      maxH = double.infinity;
    } else {
      maxH = tc.draw(_finiteDoubles(minH, finiteMaxH), label: 'maxH');
    }

    return BoxConstraints(
      minWidth: minW,
      maxWidth: maxW,
      minHeight: minH,
      maxHeight: maxH,
    );
  });
}

/// Generates non-negative [BorderRadius] values.
///
/// When [circularOnly] is `true`, uses [BorderRadius.circular].
Generator<BorderRadius> borderRadii({
  double minRadius = 0.0,
  double maxRadius = 100.0,
  bool circularOnly = false,
}) {
  _validateRange(
    minRadius,
    maxRadius,
    'borderRadii',
    minLabel: 'minRadius',
    maxLabel: 'maxRadius',
    nonNegative: true,
  );
  final radiusGen = _finiteDoubles(minRadius, maxRadius);
  return Generator.composite<BorderRadius>((tc) {
    if (circularOnly) {
      return BorderRadius.circular(tc.draw(radiusGen, label: 'radius'));
    }
    return BorderRadius.only(
      topLeft: Radius.circular(tc.draw(radiusGen, label: 'topLeft')),
      topRight: Radius.circular(tc.draw(radiusGen, label: 'topRight')),
      bottomLeft: Radius.circular(tc.draw(radiusGen, label: 'bottomLeft')),
      bottomRight: Radius.circular(tc.draw(radiusGen, label: 'bottomRight')),
    );
  });
}

/// Picks a [Locale] from [choices] (or a curated default set covering LTR, RTL, and CJK scripts).
Generator<Locale> locales([List<Locale>? choices]) {
  final effective = choices ?? _defaultLocales;
  if (effective.isEmpty) {
    throw ArgumentError.value(choices, 'choices', 'locales: must not be empty');
  }
  return sampled(effective);
}

/// Generates [TextDirection] values (`ltr`, `rtl`).
Generator<TextDirection> textDirections() => sampled(TextDirection.values);

/// Generates [Brightness] values (`dark`, `light`).
Generator<Brightness> brightnesses() => sampled(Brightness.values);

/// Generates [ThemeMode] values (`system`, `light`, `dark`).
Generator<ThemeMode> themeModes() => sampled(ThemeMode.values);

/// Generates linear [TextScaler] values with scale factor in `[minScale, maxScale]`.
Generator<TextScaler> textScalers({
  double minScale = 0.5,
  double maxScale = 3.0,
}) {
  _validateRange(
    minScale,
    maxScale,
    'textScalers',
    minLabel: 'minScale',
    maxLabel: 'maxScale',
    positive: true,
  );
  return _finiteDoubles(minScale, maxScale).map(TextScaler.linear);
}

/// Generates [Alignment] values, covering both standard corner/edge presets and continuous `[-1, 1]` coordinates.
Generator<Alignment> alignments() {
  final coord = _finiteDoubles(-1.0, 1.0);
  return oneOf([
    sampled(_presetAlignments),
    Generator.composite<Alignment>(
      (tc) => Alignment(tc.draw(coord, label: 'x'), tc.draw(coord, label: 'y')),
    ),
  ]);
}
