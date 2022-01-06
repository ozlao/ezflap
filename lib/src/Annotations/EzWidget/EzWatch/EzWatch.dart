
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

/// Full documentation: https://www.ezflap.io/essentials/watches/watches.html
///
/// Watches are methods with the @EzWatch annotation.
/// Watches are invoked when the reactive value they watch is updated.
class EzWatch extends EzAnnotationBase {
	/// The expression to watch. Can also be the Assigned Name of a prop, model,
	/// bound field, or a computed.
	final String watchedExpression;

	const EzWatch(this.watchedExpression);
}