
import 'package:meta/meta.dart';

@immutable
class ZssAttrCondition { // currently supporting only presence and equality
	final String name;
	final String value;

	const ZssAttrCondition(this.name, this.value);

	/// returns true if the entire content is in quotes. e.g.:
	///   [hello=world] --> returns false.
	///   [hello="world"] --> returns true.
	///   [hello='world'] --> returns true.
	///   [hello='world'+'shijie'] --> returns false.
	bool isHardcoded() {
		if (value.length < 3) {
			return false;
		}

		String ch = value[0];
		if (ch != "\"" && ch != "'") {
			return false;
		}

		int len = value.length;
		if (value[len - 1] != ch) {
			return false;
		}

		if (value.indexOf(ch, 1) != len - 1) {
			return false;
		}

		return true;
	}

	String getUnquotedValue() {
		if (!this.isHardcoded()) {
			return this.value;
		}

		return this.value.substring(1, this.value.length - 1);
	}
}
