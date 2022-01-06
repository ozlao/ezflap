
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/routing/routing.html
///
/// ezFlap can be used alongside any routing method.
/// However, if route parameters are available in Flutter's native [ModalRoute]
/// (i.e. in `ModalRoute.of(this.context).settings.arguments`) - then ezFlap's
/// `@EzRouteParam` annotation can be used to easily access them.
class EzRouteParam extends EzAnnotationBase {
	/// The route param's Assigned Name.
	final String name;

	const EzRouteParam(this.name);
}