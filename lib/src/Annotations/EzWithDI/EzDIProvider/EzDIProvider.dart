
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';
import 'package:ezflap/src/Service/DependencyInjector/ResolverBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/di/di.html#injection-provider
///
/// Inject a dependency using a custom resolver for which a provider can be
/// selected in runtime.
class EzDIProvider extends EzAnnotationBase {
	/// The class of the resolver service, i.e. the service that extends
	/// [ResolverBase].
	final dynamic resolverType;

	const EzDIProvider(this.resolverType);
}
