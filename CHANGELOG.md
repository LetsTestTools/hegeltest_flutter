## 0.9.1

- **Fix**: Inject `MediaQuery` and `Directionality` inside `MaterialApp.builder` in `hegelFlutterLayoutSweepTest()` so routes, dialogs, and overlays inherit swept viewport sizes, text scales, brightness, and keyboard insets instead of being overwritten by `MaterialApp`'s root view query.
- **Fix**: Synchronize `tester.view.viewInsets` and `tester.platformDispatcher` overrides in `hegelFlutterLayoutSweepTest()` and reset all view/dispatcher overrides on teardown.
- **New**: Add `LayoutSweepConfig.validate()` to fail fast with `ArgumentError` on non-positive, non-finite, inverted, or empty sweep bounds and option lists.
- **New**: Add optional `Generator<String>? textGenerator` parameter to `hegelFlutterMonkeyTest()` for customizing `SemanticsAction.setText` inputs.
- **Fix**: Validate `steps >= 0` and check `tester.takeException()` immediately after the initial `pumpWidget` in `hegelFlutterMonkeyTest()`.
- **Fix**: Propagate `machine.tearDown()` failures in `hegelFlutterStatefulTest()` when the test body succeeded, and validate `HEGEL_SEED` as an integer.
- **Fix**: Automatically stage the bundled `libhegel` binary into `.dart_tool/lib/` atomically under `flutter test` so tests run out-of-the-box without requiring `HEGEL_LIBHEGEL_PATH`.

## 0.9.0

- **New**: Bump `hegeltest` dependency to `^0.9.0`, bringing `tc.classify()`, `tc.cover()`, `sampledWeighted()`, and `oneOfWeighted()` to Flutter
- **New**: Minimum distribution coverage assertions via `tc.cover()` with `InsufficientCoverageException` in Flutter tests
- **New**: Direct weighted sampling with `sampledWeighted()` and `oneOfWeighted()` combinators

## 0.8.0

- **New**: `hegelFlutterMonkeyTest()` — Accessibility/Semantics monkey fuzzing for Flutter widgets and entire apps
  - Traverses the active `SemanticsOwner` tree and discovers interactive accessibility nodes
  - Dispatches fuzzed actions (`tap`, `longPress`, `scroll`, `setText`, `increase`/`decrease`, `dismiss`)
  - Automatically shrinks failing action sequences to minimal reproducing steps with trace logs
  - Supports `allowedActions` filtering, `stepInvariant`, and `invariant` callbacks
- **New**: `hegelFlutterLayoutSweepTest()` — Comprehensive screen size and layout invariant sweep testing
  - Sweeps viewports across logical widths, heights, dynamic `TextScaler` font scales, LTR/RTL text directions, device pixel ratios, and keyboard insets
  - Automatically detects `RenderFlex overflowed` and framework layout errors
  - Shrinks breaking viewports and font scales to find minimal boundary failure conditions
  - Provides `LayoutSweepConfig`, `LayoutSample`, and `LayoutOverflowException` with automatic view size cleanup
- **New**: Re-export `SemanticsAction` from `package:flutter/rendering.dart` in barrel file

## 0.7.0

- **New**: Bump `hegeltest` dependency to `^0.8.0`, bringing persistent counterexample database caching to Flutter
- **New**: Automatic `.hegel/examples/` caching of failing counterexamples with instant replay on iteration 1
- **New**: Auto-derived `databaseKey` scoped to test descriptions across unit, widget, and stateful test runners
- **New**: Support `database: false` opt-out, `HEGEL_DATABASE=0` env var, and custom `databasePath` directory
- **Docs**: Comprehensive database documentation and CI caching configuration in README

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
