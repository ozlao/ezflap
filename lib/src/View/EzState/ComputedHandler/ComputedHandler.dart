
import 'dart:async';

import 'package:ezflap/src/Utils/Guid/Guid.dart';
import 'package:ezflap/src/Utils/Rx/RxWrapper/RxWrapper.dart';
import 'package:ezflap/src/Utils/Tick/Tick.dart';
import 'package:ezflap/src/Utils/Types/Types.dart';
import 'package:get/get_rx/get_rx.dart';

class $ComputedHandler<T> extends Guid {
	final T Function() funcInvokeUserFunction; // e.g. () => this._computedAnswer()
	final RxWrapper<T> _cachedValue = RxWrapper();
	final Rx<bool> _rxDirty = false.obs;
	final RxNotifier _observer = RxNotifier();
	late StreamSubscription _sub;
	TFuncCancel? _funcCancelDirtyTick;
	final Rx<bool> _rxDummy = false.obs;

	$ComputedHandler({ required this.funcInvokeUserFunction }) {
		this._sub = this._observer.listen((evt) {
			this._markAsDirty();
		});
	}

	void _markAsDirty() {
		if (this._rxDirty.value) {
			// already marked as dirty; nothing to do
			return;
		}

		this._rxDirty.value = true;

		// the value will be re-calculated on the next read (i.e. call to
		// getWithCache()). this is useful because the factors of an EzComputed
		// can change multiple times during a single tick, without the EzComputed
		// needing to be re-calculated. so we just flag it as dirty, and will
		// only re-calculate it if actually requested.
		// HOWEVER, this is not enough, because if its value is to be changed,
		// then a re-render may be needed. if we don't re-calc, then
		// this._cachedValue is not updated, the observer is not notified, and
		// our EzComputed is no longer reactive.
		// to fix this, we schedule a recalculation for the next tick.

		this._funcCancelDirtyTick = Tick.nextTick(() {
			this._funcCancelDirtyTick = null;

			if (!this._rxDirty.value) {
				// no longer dirty. this can happen if getWithCache() was
				// called before this callback was invoked (e.g. if it was
				// called in the previous tick after an EzComputed factor was
				// changed, or if a build() was already scheduled by the
				// previous tick and got invoked in our current tick, but
				// before us (i'm not sure how Duration(0) ticks are scheduled,
				// but i'm guessing they are invoked in the order they were
				// scheduled, in which case it's probably possible for a build()
				// to have been requested before this callback was scheduled).
				return;
			}

			// still dirty, recalc.
			this._calc();
		});
	}

	void _clearDirty() {
		this._rxDirty.value = false;

		// if we already scheduled recalc in the next tick - cancel it, because
		// no need to recalculating when not dirty. if we got here then it means
		// that we already recalculated.
		this._cancelDirtyTickIfNeeded();
	}

	bool _isDirty() {
		return this._rxDirty.value;
	}

	void _calc() {
		T value = RxInterface.notifyChildren(this._observer, () {
			// if the user's function doesn't access any reactive data then
			// obx throws an exception. so we will always access this dummy.
			_rxDummy.value;

			// and now - invoke the user's function.
			return this.funcInvokeUserFunction();
		});
		this._cachedValue.setValue(value);
		this._clearDirty();
	}

	void _cancelDirtyTickIfNeeded() {
		if (this._funcCancelDirtyTick != null) {
			this._funcCancelDirtyTick!();
			this._funcCancelDirtyTick = null;
		}
	}

	void dispose() {
		this._cancelDirtyTickIfNeeded();
		this._sub.cancel();
		this._observer.close();
	}

	T getWithCache() {
		if (!this._cachedValue.wasInit() || this._isDirty()) {
			this._calc();
		}
		return this._cachedValue.getValue();
	}
}
