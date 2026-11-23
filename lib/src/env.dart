import 'dart:io';

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
