
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

/// Full documentation: https://www.ezflap.io/essentials/bound-methods/bound-methods.html
///
/// Bound methods are useful in these scenarios:
///  - Retrieve or calculate a value that depends on parameters (e.g. inside a z-for loop).
///  - Assign bound methods to handle events as the user interacts with the UI (with z-on).
///
/// Some properties of bound methods:
///  - Bound methods are accessible in the ZML.
///  - Unlike computed methods, the value returned from bound methods is not cached.
///  - Bound methods may return a value, but can also have a void return type.
///  - Bound methods may accept parameters.
///  - Bound methods are never asynchronous.
class EzMethod extends EzAnnotationBase {
	/// The bound method's Assigned Name.
	final String name;

	const EzMethod(this.name);
}