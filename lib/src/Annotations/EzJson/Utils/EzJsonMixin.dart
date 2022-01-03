
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/GenericFieldVisitor.dart';

class EzJsonMixin {
	String getThisCodeByField(GenericFieldData data) {
		String sThis = "this";
		if (!data.startsWithDontTouchPrefix) {
			// we're changing an actual member
			sThis = "(this as dynamic)";
		}
		return sThis;
	}
}