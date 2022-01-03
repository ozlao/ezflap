
import 'package:get/get_rx/get_rx.dart';

class RxWrapper<T> {
	bool _isInit = false;
	late Rx<T> _rx;

	RxWrapper();

	factory RxWrapper.withValue(T value) {
		RxWrapper<T> rxw = RxWrapper();
		rxw._setInitialValue(value);
		return rxw;
	}

	factory RxWrapper.withRx(Rx<T> rx) {
		RxWrapper<T> rxw = RxWrapper();
		rxw._rx = rx;
		rxw._isInit = true;
		return rxw;
	}

	static RxWrapper<U> $wrapWithRxWrapperIfRx<U>(dynamic maybeRx) {
		if (maybeRx is RxWrapper<U>) {
			return maybeRx;
		}
		else if (maybeRx is Rx<U>) {
			return RxWrapper.withRx(maybeRx);
		}
		else {
			throw "RxWrapper.\$wrapWithRxWrapperIfRx Expected to get an RxWrapper<${U}> or Rx<${U}>, but got something of type: ${maybeRx.runtimeType}";
		}
	}

	Rx<T> getRx() {
		return this._rx;
	}

	Rx<T>? tryGetRx() {
		return (this.wasInit() ? this._rx : null);
	}

	T getValue() {
		return this._rx.value;
	}

	T getValueAndSetDefaultIfNotInit(T defaultValue) {
		if (!this.wasInit()) {
			this.setValue(defaultValue);
		}
		return this.getValue();
	}

	void setValue(T value) {
		if (this._isInit) {
			this._rx.value = value;
		}
		else {
			this._setInitialValue(value);
		}
	}

	void _setInitialValue(T value) {
		this._isInit = true;
		this._rx = Rx<T>(value);
	}

	bool wasInit() {
		return this._isInit;
	}
}
