
class _InvocationData {
	final String key;
	final String? extra;
	final List<dynamic>? arrParams;

	_InvocationData({ required this.key, this.extra, this.arrParams });
}

class TestWrapperMixin {
	Map<String, List<_InvocationData>> _mapInvocations = { };

	void tw_logInvocation(String key, { String? extra, List<dynamic>? arrParams }) {
		_InvocationData data = _InvocationData(
			key: key,
			extra: extra,
			arrParams: arrParams,
		);
		this._mapInvocations[key] ??= [ ];
		this._mapInvocations[key]!.add(data);
	}

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

	void tw_reset() {
		this._mapInvocations = { };
	}

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

	dynamic tw_getParam(String key, int paramIdx) {
		return this._mapInvocations[key]!.last.arrParams![paramIdx];
	}
}