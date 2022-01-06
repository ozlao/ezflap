
import 'package:meta/meta.dart';

@internal
class $ModelHandler<T> {
	late T Function() _funcGetModelValue;
	late void Function(T value) _funcSetModelValue;

	$ModelHandler({
		required T Function() funcGetModelValue,
		required void Function(T value) funcSetModelValue,
	}) {
		this._funcGetModelValue = funcGetModelValue;
		this._funcSetModelValue = funcSetModelValue;
	}

	T getModelValue() {
		return this._funcGetModelValue();
	}

	void setModelValue(T value) {
		this._funcSetModelValue(value);
	}
}
