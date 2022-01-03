
import 'dart:async';

import 'package:ezflap/src/Utils/Tick/Tick.dart';
import 'package:ezflap/src/Utils/Types/Types.dart';
import 'package:get/get_rx/get_rx.dart';

class $WatchHandler<T> {
	final dynamic Function() funcGetWatchedValueOrRxWrapperOrRx;
	final void Function(T newValue, T oldValue) funcOnChange;
	final RxNotifier _observer = RxNotifier();
	late StreamSubscription _sub;
	final Rx<bool> _rxDummy = false.obs;
	bool _lastValueWasSet = false;
	late T _lastValue;
	TFuncCancel? _funcCancelNotificationTick;
	TFuncCancel? _funcCancelRecheckValueTick;
	late T _pendingNotificationOldValue;
	late T _pendingNotificationNewValue;

	$WatchHandler({
		required this.funcGetWatchedValueOrRxWrapperOrRx,
		required this.funcOnChange,
	}) {
		this._sub = this._observer.listen((evt) {
			this._onInitOrUpdated();
		});
		this._onInitOrUpdated(); // kick it off
	}

	bool _trySetLastValue() {
		dynamic value = this.funcGetWatchedValueOrRxWrapperOrRx();
		dynamic effectiveValue = value;

		this._lastValue = effectiveValue as T;
		this._lastValueWasSet = true;
		return true;
	}

	void _onInitOrUpdated() {
		RxInterface.notifyChildren(this._observer, () {
			// if the user's function doesn't access any reactive data then
			// obx throws an exception. so we will always access this dummy.
			_rxDummy.value;

			if (!this._lastValueWasSet) {
				this._trySetLastValue();
				return;
			}

			if (this._funcCancelRecheckValueTick != null) {
				// already scheduled value re-check
				return;
			}
			
			this._funcCancelRecheckValueTick = Tick.nextTick(() {
				this._funcCancelRecheckValueTick = null;
				
				T localLastValue = this._lastValue;
				this._trySetLastValue();
	
				T newValue = this._lastValue;
				this._scheduleNotificationIfNeeded(newValue, localLastValue);
			});
		});
	}

	void _scheduleNotificationIfNeeded(T newValue, T oldValue) {
		if (this._funcCancelNotificationTick != null) {
			// already has pending notification. update the new value so that
			// when it gets invoked - the notification will contain the latest
			// one, but don't actually call twice.
			this._pendingNotificationNewValue = newValue;
			return;
		}

		if (newValue == oldValue) {
			return;
		}

		// schedule!
		this._pendingNotificationNewValue = newValue;
		this._pendingNotificationOldValue = oldValue;
		this._funcCancelNotificationTick = Tick.nextTick(() {
			this._funcCancelNotificationTick = null;
			this.funcOnChange(this._pendingNotificationNewValue, this._pendingNotificationOldValue);
		});
	}

	void dispose() {
		this._funcCancelNotificationTick?.call();
		this._funcCancelRecheckValueTick?.call();
		this._sub.cancel();
		this._observer.close();
	}
}
