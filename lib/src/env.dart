import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

/// Returns the seed from the `HEGEL_SEED` environment variable, or `null`
/// if the variable is unset or empty.
///
/// Throws [ArgumentError] if `HEGEL_SEED` is set to a non-integer value.
int? envSeed() {
  final raw = Platform.environment['HEGEL_SEED'];
  if (raw == null || raw.isEmpty) return null;
  final parsed = int.tryParse(raw);
  if (parsed == null) {
    throw ArgumentError(
      'HEGEL_SEED environment variable must be a valid integer, '
      'got: "$raw"',
    );
  }
  return parsed;
}

/// Ensures the bundled `libhegel` binary from `package:hegeltest` is staged in
/// `.dart_tool/lib/` when running under `flutter test`.
///
/// Unlike `dart test`, `flutter test` does not automatically populate
/// `.dart_tool/lib/` for `DynamicLibrary.open`-based loaders. Staging the
/// bundled binary ensures `flutter test` works out-of-the-box without requiring
/// `HEGEL_LIBHEGEL_PATH`.
void ensureFlutterNativeAssets() {
  final envPath = Platform.environment['HEGEL_LIBHEGEL_PATH'];
  if (envPath == null || envPath.isEmpty) {
    _stageBundledBinaryIfNeeded();
  }
}

void _stageBundledBinaryIfNeeded() {
  try {
    final libName = _platformLibName();
    final targetFile = File('.dart_tool/lib/$libName');
    if (targetFile.existsSync()) return;

    final packageRootUri = _resolveHegeltestPackageRoot();
    if (packageRootUri == null) return;

    final dirName = '${Platform.operatingSystem}_${_currentArch()}';
    final bundledUri = packageRootUri.resolve('native/$dirName/$libName');
    final bundledFile = File.fromUri(bundledUri);
    if (!bundledFile.existsSync()) return;

    targetFile.parent.createSync(recursive: true);
    bundledFile.copySync(targetFile.path);
  } catch (_) {
    // Best-effort staging; loadHegelLibrary() will report a clear error if loading fails.
  }
}

Uri? _resolveHegeltestPackageRoot() {
  try {
    final packageLibUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:hegeltest/hegeltest.dart'),
    );
    if (packageLibUri != null) {
      return packageLibUri.resolve('../');
    }
  } catch (_) {
    // Isolate.resolvePackageUriSync throws UnsupportedError in flutter_tester
  }

  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) return null;

  final decoded = jsonDecode(configFile.readAsStringSync());
  if (decoded is! Map<String, dynamic>) return null;
  final packages = decoded['packages'];
  if (packages is! List) return null;

  for (final pkg in packages) {
    if (pkg is Map<String, dynamic> && pkg['name'] == 'hegeltest') {
      final rootUriStr = pkg['rootUri'];
      if (rootUriStr is String && rootUriStr.isNotEmpty) {
        final normalized = rootUriStr.endsWith('/')
            ? rootUriStr
            : '$rootUriStr/';
        return configFile.absolute.uri.resolve(normalized);
      }
    }
  }
  return null;
}

String _platformLibName() {
  if (Platform.isMacOS) return 'libhegel_c.dylib';
  if (Platform.isLinux) return 'libhegel_c.so';
  if (Platform.isWindows) return 'hegel_c.dll';
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

String _currentArch() {
  final abi = Abi.current();
  if (abi == Abi.macosArm64 ||
      abi == Abi.linuxArm64 ||
      abi == Abi.windowsArm64) {
    return 'arm64';
  }
  if (abi == Abi.macosX64 || abi == Abi.linuxX64 || abi == Abi.windowsX64) {
    return 'x64';
  }
  return abi.toString();
}
