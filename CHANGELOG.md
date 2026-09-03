## 0.6.0

- **New**: Bump `hegeltest` dependency to `^0.7.0`, bringing `tc.collect()` observation statistics API to Flutter
- **Example**: Update `example/main.dart` demonstrating `tc.collect()` in unit tests, widget configuration sweeps, and standalone runners
- **Docs**: Expand README with `tc.collect()` statistics distribution guidance and programmatic runner usage

## 0.5.1

- **New**: `example/main.dart` — complete examples for unit, widget, and stateful property testing
- **Docs**: Fix `strings()` generator typo to `text()` in README widget test example
- **Docs**: Add complete self-contained `CounterMachine` implementation in README
- **Docs**: Document `runHegelFlutterTest()` standalone runner in README

## 0.5.0

- **New**: `runHegelFlutterTest()` — standalone property runner returning `RunResult` without `test()` wrapper
- Bump `hegeltest` dependency to `^0.6.1`
- **Docs**: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue/PR templates

## 0.4.0

- **New**: `hegelFlutterWidgetTest()` — property-based testing for Flutter widgets

## 0.3.0

- **Breaking**: Minimum Dart SDK bumped to `>=3.10.0`, Flutter `>=3.38.0`
- Bump `hegeltest` dependency to `^0.5.0` (Native Assets integration)
- Native library now auto-resolved via Dart Build Hooks — no manual setup needed

## 0.2.0

- **New**: `hegelFlutterStatefulTest()` — stateful testing compatible with `flutter_test`
- Bump `hegeltest` dependency to `^0.4.0`
- Re-exports `StateMachine`, `StateRule`, `StateInvariant`, `Pool<T>` from hegeltest

## 0.1.0

- Initial release
- `hegelFlutterTest()` — property-based testing compatible with `flutter_test`
- Re-exports all generators and types from `package:hegeltest` v0.2.0
- Supported platforms: macOS arm64, Linux x64/arm64, Windows x64/arm64
