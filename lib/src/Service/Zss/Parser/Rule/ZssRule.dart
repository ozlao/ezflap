
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:meta/meta.dart';

@immutable
class ZssRule {
	final List<ZssSelectorPart> arrSelectorParts;
	final Map<String, StylingTag> mapNamedStylingTags; // e.g. <decoration->...</decoration->
	final String originalSelector; // the selector from the user's ZSS, as-is
	late final int specificity;

	ZssRule({
		required this.arrSelectorParts,
		required this.mapNamedStylingTags,
		required this.originalSelector,
	}) {
		this.specificity = this.arrSelectorParts.sum((x) => x.calcSpecificity());
	}

	@override
	String toString() {
		return "ZssRule: [${this.specificity}] ${this.originalSelector} (${this.mapNamedStylingTags.keys.join(", ")})";
	}
}
