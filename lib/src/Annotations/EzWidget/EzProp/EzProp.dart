
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/props/props.html
///
/// Native Flutter widgets receive data from their host widgets using
/// constructor parameters; ezFlap widgets use Props instead.
///
/// A Prop is similar to a constructor parameter, only that instead of being
/// specified in a constructor - it is specified as a field in the widget class,
/// and marked with the @EzProp annotation.
class EzProp extends EzAnnotationBase {
	/// The prop's Assigned Name.
	final String name;

	const EzProp(this.name);
}