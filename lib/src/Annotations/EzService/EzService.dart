
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

class EzService extends EzAnnotationBase {
	/// When not null, [overrideBaseClassType] denotes the parent of the
	/// generated service base. Can be:
	///  - a type, to denote the class to extend.
	///  - a String, to denote the literal to be used when extending.
	///    this is useful when the base class has generic parameters; it seems
	///    to cause Dart's Analyzer to crash.
	final dynamic overrideBaseClassType;

	const EzService([ this.overrideBaseClassType ]);
}