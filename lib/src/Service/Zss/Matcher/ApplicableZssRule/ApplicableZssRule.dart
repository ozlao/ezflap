
import 'package:ezflap/src/Service/Zss/Matcher/ApplicableZssSelectorPart/ApplicableZssSelectorPart.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';

class ApplicableZssRule {
	final List<ApplicableZssSelectorPart> arrApplicableSelectorParts;

	// the root Tag of the style that is (potentially) provided to the
	// parameter.
	final StylingTag styleRootTag;

	final int specificity;

	ApplicableZssRule({
		required this.arrApplicableSelectorParts,
		required this.styleRootTag,
		required this.specificity,
	});
}
