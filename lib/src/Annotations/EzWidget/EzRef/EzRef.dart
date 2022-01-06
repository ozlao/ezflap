
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/refs/refs.html
///
/// Refs allow a host widget to access the public functions and fields of a
/// hosted widget.
class EzRef extends EzAnnotationBase {
	/// The ref's Assigned Name.
	final String name;

	const EzRef(this.name);
}