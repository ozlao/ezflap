
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';

class ZssSelectorPart {
	// this is not technically correct for CSS; class will always surpass tags,
	// but it's easier and more efficient to work with integers, and if we ever
	// have a selector with 100 tags then ZSS specificity will probably be the
	// least of our problems...
	static const _SPECIFICITY_VALUE_TAG = 1;
	static const _SPECIFICITY_VALUE_CLASS_ATTR = 100;

	String? tagName;
	Set<String>? setClasses;
	Map<String, ZssAttrCondition?>? mapAttrConditions; // null _AttrCondition means that we just need to check for existence
	bool isForParameter = false;

	int calcSpecificity() {
		int specificity = 0;
		if (this.tagName != null) {
			specificity += _SPECIFICITY_VALUE_TAG;
		}
		if (this.setClasses != null) {
			specificity += (this.setClasses!.length * _SPECIFICITY_VALUE_CLASS_ATTR);
		}
		if (this.mapAttrConditions != null) {
			specificity += (this.mapAttrConditions!.length * _SPECIFICITY_VALUE_CLASS_ATTR);
		}
		return specificity;
	}

	ZssSelectorPart mergeFromIntoNew(ZssSelectorPart other) {
		assert(this.tagName == null || other.tagName == null || this.tagName == other.tagName, "extender selector conflicts with parent selector");
		ZssSelectorPart mergedSelectorPart = new ZssSelectorPart();
		mergedSelectorPart.tagName = this.tagName ?? other.tagName;
		mergedSelectorPart.setClasses = { ...(this.setClasses ?? { }), ...(other.setClasses ?? { }) };
		mergedSelectorPart.mapAttrConditions = { ...(this.mapAttrConditions ?? { }), ...(other.mapAttrConditions ?? { }) };
		mergedSelectorPart.isForParameter = (this.isForParameter || other.isForParameter);
		return mergedSelectorPart;
	}

	@override
	String toString() {
		return "ZssSelectorPart: ${this.tagName}, ${this.setClasses?.join(".")}, [${this.mapAttrConditions?.keys.join(", ")}]";
	}
}
