
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

/// Full documentation: https://www.ezflap.io/essentials/bound-fields/bound-fields.html
///
/// - Bound fields are accessible from the ZML using their Assigned Name.
/// - Bound fields are reactive; whenever the value of an ezFlap bound field
///   changes - the widget's `build()` method is called automatically, and the
///   display is refreshed to reflect the new value.
class EzField extends EzAnnotationBase {
	/// The Assigned Name of the bound field.
	final String name;

	const EzField(this.name);
}