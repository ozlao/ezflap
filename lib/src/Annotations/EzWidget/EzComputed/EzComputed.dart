
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation: https://www.ezflap.io/essentials/computed/computed.html
///
/// Computed methods are invoked when ZML that references them is rendered.
///
/// The value a computed method returns is used in the ZML, in the spot where it is referenced.
///  - Computed methods are accessible in the ZML.
///  - Computed methods always return a value.
///  - Computed methods do not accept parameters.
///  - Computed methods are never asynchronous.
///  - The value returned from computed methods is cached.
///  - Computed methods are useful when we need to perform a transformation of some data before exposing it to the ZML. For example, we might want to format a string or filter a list.
class EzComputed extends EzAnnotationBase {
	/// The Assigned Name of the computed method.
	final String name;

	const EzComputed(this.name);
}