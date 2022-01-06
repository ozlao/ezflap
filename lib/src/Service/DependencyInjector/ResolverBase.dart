
import 'package:ezflap/src/Service/DependencyInjector/ProviderBase.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/di/di.html#injection-provider
///
/// Extend this class to create a resolver service that would resolve providers
/// of type [T] into fields annotated with `@EzDIProvider` (that is configured
/// to use the resolver).
/// The extending class does not need to add or override any functionality
/// (though it may provide additional functionality).
/// The main (and usually only) reason to extend [ResolverBase] is to use the
/// Dart types system to enforce the connection between resolvers and their
/// suitable providers.
abstract class ResolverBase<T extends ProviderBase> extends EzServiceBase {
	T? _current;

	/// Call this function to set the current provider to inject into fields
	/// with an `@EzDIProvider` configured with this resolver.
	void setProvider(T? provider) {
		T? previousProvider = this._current;

		this._current = provider;

		if (previousProvider != null) {
			this._current?.hookDetachedFromResolver();
		}
		provider?.hookAttachedToResolver();
	}

	/// Call this method to get the current provider of this resolver. Note
	/// that it's usually not necessary to call this method; the provider
	/// resolution is done automatically by `@EzDIProvider`.
	T resolve() {
		if (this._current == null) {
			throw "cannot resolve. current provider is null.";
		}
		return this._current!;
	}
}