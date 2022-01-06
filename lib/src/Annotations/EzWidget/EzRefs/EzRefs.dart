
import 'package:ezflap/src/Annotations/Utils/EzAnnotationBase/EzAnnotationBase.dart';

/// Full documentation: https://www.ezflap.io/deep-dive/refs/refs.html#multiple-widgets
///
/// Refs allow a host widget to access the public functions and fields of a
/// set of hosted widgets generated with a z-for.
class EzRefs extends EzAnnotationBase {
	/// The refs' Assigned Name.
	final String name;

	/// The type to use for the keys of the refs [Map].
	final Type keyType;

	const EzRefs(this.name, [ this.keyType = String ]);
}