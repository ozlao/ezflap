
class _InvocationData {
	final String key;
	final String? extra;
	final List<dynamic>? arrParams;

	_InvocationData({ required this.key, this.extra, this.arrParams });
}

/// Full documentation: https://www.ezflap.io/testing/mock/mock.html#log-function-calls
///
/// This mixin offers some utility functions that can be used by mocks to keep
/// track of invocations of the mocked service's methods.
class TestWrapperMixin {
	Map<String, List<_InvocationData>> _mapInvocations = { };

	/// Log a method invocation.
	///  - [key]: an arbitrary identifier that should be unique within the
	///    class. Usually the name of the invoked method.
	///  - [extra]: an optional arbitrary text to be associated with this method
	///    invocation. Can be checked later, with [tw_getExtraOfLastInvocation].
	///  - [arrParams]: an optional [List] of the parameters provided to the
	///    method invocation.
	void tw_logInvocation(String key, { String? extra, List<dynamic>? arrParams }) {
		_InvocationData data = _InvocationData(
			key: key,
			extra: extra,
			arrParams: arrParams,
		);
		this._mapInvocations[key] ??= [ ];
		this._mapInvocations[key]!.add(data);
	}

	/// Check whether a method was invoked at least, at most, or exactly a
	/// given number of times.
	bool tw_wasInvoked({ String? key, int? atLeastNumTimes, int? atMostNumItems, int? exactlyNumTimes }) {
		assert(exactlyNumTimes == null || (atLeastNumTimes == null && atMostNumItems == null));

		List<_InvocationData> arrToCheck = [ ];
		if (key == null) {
			for (List<_InvocationData> arr in this._mapInvocations.values) {
				arrToCheck.addAll(arr);
			}
		}
		else if (this._mapInvocations.containsKey(key)) {
			arrToCheck = this._mapInvocations[key]!;
		}
		else {
			if (exactlyNumTimes != null && exactlyNumTimes == 0) {
				return true;
			}
			return false;
		}

		//int numTimes = this._mapInvocations[key]!.length;
		int numTimes = arrToCheck.length;
		if (atLeastNumTimes != null && numTimes < atLeastNumTimes) {
			return false;
		}
		if (atMostNumItems != null && numTimes > atMostNumItems) {
			return false;
		}
		if (exactlyNumTimes != null && numTimes != exactlyNumTimes) {
			return false;
		}

		if ((atLeastNumTimes ?? atMostNumItems ?? exactlyNumTimes) == null) {
			return (numTimes > 0);
		}

		return true;
	}

	/// Clear the log of invocations that have been recorded so far for this
	/// instance.
	void tw_reset() {
		this._mapInvocations = { };
	}

	/// Retrieve the `extra` text that was provided to [tw_logInvocation] in the
	/// last invocation that was recorded with [key].
	/// If [key] is null - return the `extra` of the last invocation of any key.
	String? tw_getExtraOfLastInvocation([ String? key ]) {
		if (!this.tw_wasInvoked(key: key)) {
			return null;
		}

		if (key == null) {
			if (this._mapInvocations.values.length != 1) {
				throw "there were multiple invocations since last clear; a key must be supplied";
			}

			return this._mapInvocations.values.first.last.extra;
		}

		return this._mapInvocations[key]!.last.extra;
	}

	/// Retrieve a parameter that was recorded with the last invocation that
	/// was recorded with [key].
	dynamic tw_getParam(String key, int paramIdx) {
		return this._mapInvocations[key]!.last.arrParams![paramIdx];
	}
}