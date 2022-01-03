
import 'dart:math' as Math;

class EZ {
	static String removeWhitespaces(String s) {
		return s.replaceAll(RegExp(r"\s+"), "");
	}

	static bool isNull(dynamic value) {
		return (value == null);
	}

	static bool? boolifyOrNull(dynamic value) {
		if (value == null) {
			return null;
		}
		return EZ.boolify(value);
	}

	static bool boolify(dynamic value) {
		bool? b = EZ.tryBoolify(value);
		if (b == null) {
			throw "don't know how to boolify [${value}]";
		}
		return b;
	}

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

	static T round<T extends num>(num n, [ int degree = 0 ]) {
		if (degree == 0) {
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

		num factor = Math.pow(10, degree);
		return EZ.round<T>(n * factor) / factor as T;
	}

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
}