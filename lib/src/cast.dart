import 'dart:core';

// ----------------------------------------------------------------------

T castOr<T>(dynamic value, T fallback) => value is T ? value : fallback;

// ----------------------------------------------------------------------

/// cast int or bool dynamaic value to bool, 0 -> false, non-zero (including negative) -> true, null -> ifNull (false)
bool castToBool(dynamic value, {bool ifNull = false}) {
  if (value == null) return ifNull;
  if (value is bool) return value;
  if (value is int) return value != 0;
  throw FormatException("cannot cast [$value] to bool");
}

// ----------------------------------------------------------------------
