/// Tolerant numeric parsing for API responses.
///
/// The backend is Laravel over MySQL, and PHP serialises DECIMAL columns as
/// JSON *strings*: money arrives as `"12.50"`, coordinates as `"29.7604000"`,
/// counts sometimes as `"6"`. A direct `as num` cast throws
///
///     type 'String' is not a subtype of type 'num?' in type cast
///
/// which kills the whole screen, not just the field. This bit the Assigned
/// Dedicated Routes screen in production: it rendered fine with no routes and
/// died the moment a driver was given one.
///
/// These helpers accept either representation. Use them for anything that
/// crosses the API boundary; a bare cast is only safe for values this app
/// created itself.
library;

/// Parses a double from a number, a numeric string, or null.
/// Returns [fallback] (default 0.0) when the value is missing or unparseable.
double jsonDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

/// Nullable variant, for genuinely optional values such as coordinates that
/// may legitimately be absent. Distinguishes "not provided" from "zero" -
/// collapsing a missing latitude to 0.0 would put the pin off West Africa.
double? jsonDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Parses an int from a number, a numeric string, or null.
/// Accepts "6.0" as 6, since a DECIMAL count can arrive with a scale.
int jsonInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  final raw = value.toString();
  return int.tryParse(raw) ?? double.tryParse(raw)?.toInt() ?? fallback;
}

/// Nullable int variant.
int? jsonIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  final raw = value.toString();
  return int.tryParse(raw) ?? double.tryParse(raw)?.toInt();
}

/// Booleans cross the wire as 1/0, "1"/"0", or true/false depending on the
/// column type and driver.
bool jsonBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final raw = value.toString().toLowerCase();
  return raw == '1' || raw == 'true' || raw == 'yes';
}
