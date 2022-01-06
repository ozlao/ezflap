
import 'dart:math' as Math;

/// Generic utilities.
class EZ {
	/// Removes all whitespaces from [s] (using the "\s" regexp).
	static String removeWhitespaces(String s) {
		return s.replaceAll(RegExp(r"\s+"), "");
	}


	/// If [value] is null - returns null. Otherwise - returns its truthy value
	/// (using [EZ.boolify]).
	static bool? boolifyOrNull(dynamic value) {
		if (value == null) {
			return null;
		}
		return EZ.boolify(value);
	}


	/// Returns the truthy value of [value], or throws an exception.
	///  - If [value] is null - returns false.
	///  - If [value] is a bool - returns [value].
	///  - If [value] is a String - returns false for "", "0", and the word
	///    "false" (case-insensitive), and true otherwise.
	///  - If [value] is a num - returns false for zero, and true otherwise.
	///  - Otherwise - throws an exception
	static bool boolify(dynamic value) {
		bool? b = EZ.tryBoolify(value);
		if (b == null) {
			throw "don't know how to boolify [${value}]";
		}
		return b;
	}


	/// Returns the truthy value of [value] (refer to [EZ.boolify] for details)
	/// or null, if the truthy value cannot be figured out (i.e. instead of
	/// throwing an exception like [EZ.boolify] does).
	static bool? tryBoolify(dynamic value) {
		if (value == null) {
			return false;
		}

		if (value is bool) {
			return value;
		}

		if (value is String) {
			if (value == "" || value == "0" || value.toLowerCase() == "false") {
				return false;
			}
			return true;
		}

		if (value is num) {
			return (value != 0);
		}

		return null;
	}


	/// Rounds [n] to a precision of [precision]. The returned value is of the
	/// same type as [n].
	static T round<T extends num>(num n, [ int precision = 0 ]) {
		if (precision == 0) {
			if (T == double || T == num) {
				return n.roundToDouble() as T;
			}
			else if (T == int) {
				return n.round() as T;
			}
			else {
				throw "can't round to type [${T}]";
			}
		}

		num factor = Math.pow(10, precision);
		return EZ.round<T>(n * factor) / factor as T;
	}


	/// Rounds [n] to the closest smaller integer. The returned value is of the
	/// same type as [n].
	static T floor<T extends num>(num n) {
		if (T == double || T == num) {
			return n.floorToDouble() as T;
		}
		else if (T == int) {
			return n.floor() as T;
		}
		else {
			throw "can't floor to type [${T}]";
		}
	}


	/// Rounds [n] to the closest largest integer. The returned value is of the
	/// same type as [n].
	static T ceil<T extends num>(num n) {
		if (T == double || T == num) {
			return n.ceilToDouble() as T;
		}
		else if (T == int) {
			return n.ceil() as T;
		}
		else {
			throw "can't ceil to type [${T}]";
		}
	}


	/// Returns true if [value] is null, an empty String, or an empty
	/// [Iterable].
	static bool isEmpty(dynamic value) {
		if (value == null) {
			return true;
		}

		if (value is String) {
			return (value == "");
		}

		if (value is Iterable) {
			return value.isEmpty;
		}

		return false;
	}
}