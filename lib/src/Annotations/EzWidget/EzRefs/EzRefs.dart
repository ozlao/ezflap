
import 'package:ezflap/src/Annotations/Utils/AnnotationUtils.dart';

class EzRefs extends EzAnnotationBase {
	final String name;
	final Type keyType;
	const EzRefs(this.name, [ this.keyType = String ]);
}