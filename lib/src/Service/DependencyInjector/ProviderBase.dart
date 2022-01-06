
import 'package:ezflap/src/Service/EzServiceBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/di/di.html#injection-provider
///
/// Extend this class to create an `@EzDIProvider`-injectable provider service.
abstract class ProviderBase extends EzServiceBase {
	/// Called when this provider is attached to a resolver (i.e. which means
	/// that it is now ready to be injected by `@EzDIProvider` fields that use
	/// its resolver class.
	void hookAttachedToResolver() {

	}

	/// Called when this provider is detached from a resolver.
	/// Note that if we attach the same provider to multiple resolvers, then
	/// this method will be called multiple times - for each resolver it is
	/// detached from.
	void hookDetachedFromResolver() {

	}
}