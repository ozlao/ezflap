
import 'dart:async';

import 'dart:collection';

typedef TFuncMapper<T, U> = U Function(T);
typedef TFuncReducer<T, U> = U Function(U, T);
typedef TFuncPredicate1<T> = bool Function(T);
typedef TFuncPredicate2<T, K> = bool Function(T, K);

/// Utility String extensions
extension StringUtilsExtension on String {
	/// Trim whitespaces at the edges, and remove all tabs from the content of
	/// the string.
	String stripTabs() {
		return this.trim().replaceAll("\t", "");
	}

	/// Splits a string into a [List] of trimmed Strings, potentially avoiding
	/// splitting in the middle of a quoted text.
	/// if [respectQuotes] is true - then the string is not split between
	/// quotes. however, this functionality is (currently?) limited:
	///   - escaping is not supported
	///   - both ' and " are supported, but even if one is enclosed by the
	///     other - it still "counts". for example, the string:
	///       "hello ' world"
	///     will count as having a beginning ' quote.
	///     in the following examples, we use the pattern " ":
	///       hello world
	///       -->
	///       hello
	///       world
	///
	///       "hello world"
	///       -->
	///       "hello world"
	///
	///       "hello world" "nihao shijie"
	///       -->
	///       "hello world"
	///       "nihao shijie"
	///
	///       'hello world' "nihao shijie"
	///       -->
	///       'hello world'
	///       "nihao shijie"
	///
	///       "hello 'world nihao' shijie"
	///       -->
	///       "hello 'world nihao' shijie"
	///
	///       "hello 'world" nihao' shijie
	///       -->
	///       "hello 'world"
	///       nihao'
	///       shijie
	///
	///       "hello 'world nihao' shijie
	///       -->
	///       "hello
	///       'world nihao'
	///       shijie
	///
	///       "hello'world" nihao'shijie
	///       -->
	///       "hello'world" nihao'shijie
	///
	///       "hello'world" nihao' shijie
	///       -->
	///       "hello'world" nihao'
	///       shijie
	///
	///       "hello'world" nihao' shijie'
	///       -->
	///       "hello'world" nihao'
	///       shijie'
	///
	///       "hello'world" ni'hao"shi jie"
	///       -->
	///       "hello'world" ni'hao"shi
	///       jie"
	List<String>? splitAndTrim(String pattern, { bool removeEmpty = true, bool respectQuotes = false }) {
		String s = this.trim();
		if (s.isEmpty) {
			return null;
		}

		List<String> arrParts = s.split(pattern);
		List<String> arrFinal = arrParts;
		if (respectQuotes) {
			arrFinal = [ ];

			int i = 0;
			while (i < arrParts.length) {
				String part = arrParts[i];
				String? ch = part._getQuoteIfOdd();
				if (ch != null) {
					// there is an unclosed quote. find where it's closed
					int nextIdx = -1;
					if (i < arrParts.length - 1) {
						nextIdx = arrParts.indexWhere((x) => x._hasOddQuotesOf(ch), i + 1);
					}

					if (nextIdx == -1) {
						// no closing quote. so ignore the single quote
					}
					else {
						// concatenate all the remaining parts until the part we found
						arrFinal.add(arrParts.sublist(i, nextIdx + 1).join(pattern));
						i = nextIdx + 1;
						continue;
					}
				}

				// no odd quote; add the part as-is
				arrFinal.add(part);
				i++;
			}
		}

		List<String> arr = arrFinal.map((x) => x.trim()).toList();
		arr.removeWhere((x) => x.isEmpty);
		return arr;
	}

	String? _getQuoteIfOdd() {
		for (String ch in const [ "'", "\"" ]) {
			if (this.count(ch).isOdd) {
				return ch;
			}
		}
		return null;
	}

	bool _hasOddQuotesOf(String ch) {
		return this.count(ch).isOdd;
	}

	/// Returns the last character of the string, or null if empty.
	String? lastChar() {
		if (this.isEmpty) {
			return null;
		}
		return this[this.length - 1];
	}

	/// Returns the number of occurrences of [pattern] in the string.
	int count(String pattern) {
		String s = this;
		int i = 0;
		int cnt = 0;
		while (i < this.length) {
			i = s.indexOf(pattern, i);
			if (i == -1) {
				break;
			}
			cnt++;
			i += pattern.length;
		}

		return cnt;
	}

	/// Capitalizes the first character of the string.
	String ucfirst() {
		return "${this[0].toUpperCase()}${this.substring(1)}";
	}

	/// Changes the first character of the string to lower-case.
	String lcfirst() {
		return "${this[0].toLowerCase()}${this.substring(1)}";
	}

}

extension ListUtils<T> on List<T> {
	void resetTo(T value) {
		this.fillRange(0, this.length, value);
		for (int idx = 0; idx < this.length; idx++) {
			this[idx] = value;
		}
	}

	T removeFirst() {
		assert(this.isNotEmpty, "called removeFirst() on an empty list");
		T item = this[0];
		this.removeAt(0);
		return item;
	}
}

extension MapUtils<K, V> on Map<K, V> {
	void addIfNotExists(K key, V value) {
		this.putIfAbsent(key, () => value);
	}

	void replaceKey(K oldKey, K newKey) {
		this[newKey] = this[oldKey]!;
		this.remove(oldKey);
	}

	Future<void> forEachAsync(Future<void> Function(V, K) func) async {
		for (MapEntry<K, V> kvp in this.entries) {
			await func(kvp.value, kvp.key);
		}
	}

	N sum<N extends num>(TFuncMapper<V, N> funcMapper) {
		return this.values.sum(funcMapper);
	}

	Map<K, V> where(bool Function(V item) predicate) {
		Iterable<MapEntry<K, V>> iter = this.entries.where((MapEntry<K, V> kvp) => predicate(kvp.value));
		return iter.asMap();
	}

	Map<K, V> whereKey(bool Function(K key) predicate) {
		Iterable<MapEntry<K, V>> iter = this.entries.where((MapEntry<K, V> kvp) => predicate(kvp.key));
		return iter.asMap();
	}

	Map<K, V> sortByString(TFuncMapper<V, String?> funcMapper, [ bool descending = false ]) {
		return this.entries.sortBy((MapEntry<K, V> kvp) => funcMapper(kvp.value), descending).asMap2();
	}

	Map<K, V> sortByKeysString(TFuncMapper<K, String> funcMapper, [ bool descending = false ]) {
		return this.entries.sortBy((MapEntry<K, V> kvp) => funcMapper(kvp.key), descending).asMap2();
	}

	Map<K, V> sortByNumeric(TFuncMapper<V, num> funcMapper, [ bool descending = false ]) {
		return this.entries.sortBy((MapEntry<K, V> kvp) => funcMapper(kvp.value), descending).asMap2();
	}

	Map<K, V> sortByKeysNumeric(TFuncMapper<K, num> funcMapper, [ bool descending = false ]) {
		return this.entries.sortBy((MapEntry<K, V> kvp) => funcMapper(kvp.key), descending).asMap2();
	}

	Map<K, V> sortByNumericByEntries(TFuncMapper<MapEntry<K, V>, num> funcMapper, [ bool descending = false ]) {
		return this.entries.sortBy((MapEntry<K, V> kvp) => funcMapper(kvp), descending).asMap2();
	}

	Map<K, V> sortByNumericArray(TFuncMapper<V, List<num>> funcGetNumericArray, [ bool descending = false ]) {
		return this.entries.sortByNumericArray((MapEntry<K, V> kvp) => funcGetNumericArray(kvp.value), descending).asMap2();
	}

	int countIf(bool Function(V item) predicate) {
		return this.values.countIf(predicate);
	}

	Map<K, V> takeWhile(bool Function(V item) predicate) {
		return this.entries.takeWhile((MapEntry<K, V> kvp) => predicate(kvp.value)).asMap2();
	}

	Map<K, V> skipWhile(bool Function(V item) predicate) {
		return this.entries.skipWhile((MapEntry<K, V> kvp) => predicate(kvp.value)).asMap2();
	}

	V? firstOrNull([ bool Function(V item)? predicate ]) {
		return this.values.firstOrNull(predicate);
	}

	V? lastOrNull([ bool Function(V item)? predicate ]) {
		return this.values.lastOrNull(predicate);
	}

	Map<String, List<V>> groupBy(String Function(V item) funcGroupKeyResolver) {
		Map<String, List<V>> odRet = Map<String, List<V>>();
		for (V item in this.values) {
			String key = funcGroupKeyResolver(item);
			odRet.putIfAbsent(key, () => [ ]);
			odRet[key]!.add(item);
		}
		return odRet;
	}

	V getBy(bool Function(V) predicate) {
		return this.values.getBy(predicate);
	}

	V? tryGetBy(bool Function(V) predicate) {
		return this.values.tryGetBy(predicate);
	}

	bool any([ bool Function(V)? predicate ]) {
		if (predicate == null) {
			return this.isNotEmpty;
		}
		return this.values.any(predicate);
	}

	Map<K, V> whereMax(TFuncMapper<V, num> funcMapper) {
		num? max = this.values.max(funcMapper);
		if (max == null) {
			return { };
		}
		return this.where((x) => funcMapper(x) == max);
	}
}

extension IterableUtils<T> on Iterable<T> {
	List<T> distinct() {
		return this.toSet().toList();
	}

	T? firstOrNull([ bool Function(T item)? predicate ]) {
		Iterable<T> iter = this;
		if (predicate != null) {
			iter = this.where(predicate);
		}

		if (iter.isEmpty) {
			return null;
		}

		return iter.first;
	}

	T? lastOrNull([ bool Function(T item)? predicate ]) {
		Iterable<T> iter = this;
		if (predicate != null) {
			iter = this.where(predicate);
		}

		if (iter.isEmpty) {
			return null;
		}

		return iter.last;
	}

	T? singleOrNull() {
		if (this.length != 1) {
			return null;
		}
		return this.single;
	}

	Iterable<U> asIterableOf<U extends T>() {
		return this.map((x) => x as U);
	}

	U reduceTo<U>(TFuncReducer<T, U> funcReducer, U defaultValue) {
		U reduced = defaultValue;
		for (T x in this) {
			reduced = funcReducer(reduced, x);
		}
		return reduced;
	}

	U sum<U extends num>([ TFuncMapper<T, U>? funcMapper ]) {
		if (funcMapper == null) {
			if (T == num || T == int || T == double) {
				return this.sum((x) => x as U);
			}
			throw "a mapper was not provided but the values' type is not numeric";
		}

		return this.reduceTo<U>((U total, T cur) => (total + funcMapper(cur)) as U, 0 as U);
	}

	double average<U extends num>([ TFuncMapper<T, U>? funcMapper ]) {
		if (this.isEmpty) {
			return 0;
		}

		U sum = this.sum(funcMapper);
		return sum / this.length;
	}

	bool all(TFuncPredicate1<T> funcPredicate) {
		return !this.any((x) => !funcPredicate(x));
	}

	U? max<U extends num>(TFuncMapper<T, U> funcMapper) {
		U? curMax;
		for (T? item in this) {
			if (item == null) {
				continue;
			}

			U value = funcMapper(item);
			if (curMax == null) {
				curMax = value;
				continue;
			}

			if (value > curMax) {
				curMax = value;
			}
		}

		return curMax;
	}

	U? min<U extends num>(TFuncMapper<T, U> funcMapper) {
		U? curMin;
		for (T? item in this) {
			if (item == null) {
				continue;
			}

			U value = funcMapper(item);
			if (curMin == null) {
				curMin = value;
				continue;
			}

			if (value < curMin) {
				curMin = value;
			}
		}

		return curMin;
	}

	Map<K, U> toMap<K, U>({ required K Function(T item)? funcKey, required U Function(T item)? funcValue }) {
		assert(funcKey != null);
		assert(funcValue != null);

		Map<K, U> map = { for (var item in this) funcKey!(item) : funcValue!(item) };
		return map;
	}

	Iterable<T> filterNull<U>([ TFuncMapper<T, U?>? funcMapper ]) {
		Iterable<T> iter;
		if (funcMapper == null) {
			iter = this.where((x) => x != null);
		}
		else {
			iter = this.where((x) => funcMapper(x) != null);
		}
		//return this.where((x) => x != null).map<T>((x) => x!);
		return iter.map<T>((x) => x!);
	}

	Iterable<U> selectMany<U>(TFuncMapper<T, Iterable<U>> funcMapper) {
		List<U> lst = [ ];
		this.filterNull().forEach((x) => lst.addAll(funcMapper(x)));
		return lst;
	}

	int countIf(TFuncPredicate1<T> predicate) {
		return this.sum((x) => predicate(x) ? 1 : 0);
	}

	List<T> sortBy(TFuncMapper<T, dynamic> funcMapper, [ bool descending = false ]) {
		List<T> lst = this.toList(growable: true);
		lst.sort((T a, T b) {
			dynamic da = funcMapper(a);
			dynamic db = funcMapper(b);

			if (da == null && db == null) {
				return 0;
			}

			int result;
			if (da == null) {
				result = -1;
			}
			else if (db == null) {
				result = 1;
			}
			else {
				result = Comparable.compare(da, db);
			}

			if (descending) {
				result *= -1;
			}

			return result;
		});
		return lst;
	}

	List<T> sortByNumeric(TFuncMapper<T, num> funcMapper, [ bool descending = false ]) {
		var lst = this.sortBy((x) => funcMapper(x), descending).toList();
		return lst;
	}

	List<T> sortByString(TFuncMapper<T, String> funcMapper, [ bool descending = false ]) {
		var lst = this.sortBy((x) => funcMapper(x), descending).toList();
		return lst;
	}

	List<T> sortByNumericArray(TFuncMapper<T, List<num>> funcGetNumericArray, [ bool isDescending = false ]) {
		List<T> lst = this.toList(growable: true);
		lst.sort((T a, T b) {
			List<num> arrV1 = funcGetNumericArray(a);
			List<num> arrV2 = funcGetNumericArray(b);
			if (arrV1.length != arrV2.length) {
				throw "arrV1.length [${arrV1.length}] is different from arrV2.length [${arrV2.length}]";
			}

			for (int i = 0; i < arrV1.length; i++) {
				num v1 = arrV1[i];
				num v2 = arrV2[i];
				if (isDescending) {
					v1 *= -1;
					v2 *= -1;
				}

				if (v1 < v2) return -1;
				if (v1 > v2) return 1;
			}

			return 0;
		});
		return lst;
	}

	List<U> mapToList<U>(TFuncMapper<T, U> funcMapper) {
		return this.map(funcMapper).toList();
	}

	FutureOr<void> each(FutureOr<void> Function(T item, int idx) func) async {
		int idx = 0;
		for (T item in this) {
			await func(item, idx);
			idx++;
		}
	}

	T getBy(bool Function(T) predicate) {
		return this.firstWhere(predicate);
	}

	T? tryGetBy(bool Function(T) predicate) {
		return this.cast<T?>().firstWhere((T? x) => predicate(x!), orElse: () => null);
	}
}

extension IterableMapEntryUtils<K, V> on Iterable<MapEntry<K, V>> {
	Map<K, V> asMap() {
		return Map.fromEntries(this);
	}
}

extension IterableMapEntryUtils2<K, T> on Iterable<MapEntry<K, T>> {
	// we use "2" suffix because otherwise Flutter confuses it with List.asMap()
	// when operating on a List.
	Map<K, T> asMap2() {
		var map2 = LinkedHashMap.fromEntries(this);
		return map2;
	}
}

extension NumUtils on num {
	int asInt() {
		return this.toInt();
	}

	double asDouble() {
		return this.toDouble();
	}
}

extension DoubleUtils on double {
	int asInt() {
		return this.toInt();
	}
}

extension IntUtils on int {
	double asDouble() {
		return this.toDouble();
	}
}

extension IterableNullableUtils<T> on Iterable<T?> {
	Iterable<T> denull() {
		return this.cast<T>();
	}
}

extension RegExpMatchUtils on RegExpMatch {
	String? firstGroupMatch() {
		for (int i = 1; i < this.groupCount; i++) {
			if (this.group(i) != null) {
				return this.group(i);
			}
		}

		return null;
	}
}

extension SymbolUtils on Symbol {
	String? getName() {
		String s = this.toString(); // Symbol("theName")
		if (!s.startsWith("Symbol(\"")) {
			return null;
		}
		return s.substring(8, s.length - 2);
	}
}