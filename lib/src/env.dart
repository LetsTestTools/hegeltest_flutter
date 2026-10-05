import 'dart:io';

/// Returns the seed from the `HEGEL_SEED` environment variable, or `null`
/// if the variable is unset or empty.
int? envSeed() {
  final raw = Platform.environment['HEGEL_SEED'];
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
}
