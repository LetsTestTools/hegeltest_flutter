/// Flutter integration for hegeltest — property-based testing for Flutter.
///
/// This package re-exports all generators and types from `package:hegeltest`,
/// and provides [hegelFlutterTest] which integrates with `flutter_test`
/// instead of `package:test`.
///
/// ```dart
/// import 'package:hegeltest_flutter/hegeltest_flutter.dart';
/// import 'package:flutter_test/flutter_test.dart';
///
/// void main() {
///   hegelFlutterTest('reverse is involutory', (tc) {
///     final xs = tc.draw(lists(integers()));
///     expect(xs.reversed.toList().reversed.toList(), equals(xs));
///   });
/// }
/// ```
library;

// Re-export all generators and types from hegeltest.
export 'package:hegeltest/hegeltest.dart'
    hide hegelTest, hegelStatefulTest; // Hide the package:test versions

export 'package:hegeltest/generators.dart';

// Export Flutter-compatible test functions.
export 'src/flutter_runner.dart'
    show hegelFlutterTest, hegelFlutterStatefulTest;
