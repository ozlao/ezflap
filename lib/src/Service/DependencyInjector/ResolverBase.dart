
import 'package:ezflap/ezflap.dart';
import 'package:ezflap/src/Service/DependencyInjector/ProviderBase.dart';

abstract class ResolverBase<T extends ProviderBase> extends EzServiceBase {
	T? _current;

	void setProvider(T? provider) {
		T? previousProvider = this._current;

		this._current = provider;

		if (previousProvider != null) {
			this._current?.hookDetachedFromResolver();
		}
		provider?.hookAttachedToResolver();
	}

	T resolve() {
		if (this._current == null) {
			throw "cannot resolve. current provider is null.";
		}
		return this._current!;
	}
}