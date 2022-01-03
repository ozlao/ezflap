
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';

class StylingTag {
	static int _nextUid = 1;
	// e.g. <decoration->...</decoration->
	final Tag tag;

	// we don't use Guid because it prevents testing (the numbers are not consistent over time)
	late int uid;

	StylingTag(this.tag) {
		this.uid = StylingTag._nextUid;
		StylingTag._nextUid++;
	}

	static void resetNextUidForTesting() {
		StylingTag._nextUid = 1;
	}

	@override
	String toString() {
		return "StylingTag: [${this.uid}], tag: ${this.tag}";
	}
}