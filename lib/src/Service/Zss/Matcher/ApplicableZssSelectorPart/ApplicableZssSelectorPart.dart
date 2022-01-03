
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';

class ApplicableZssSelectorPart {
	final ZssSelectorPart selectorPart;

	// the Tag for which the SelectorPart applies
	final Tag appliedForTag;

	ApplicableZssSelectorPart({
		required this.selectorPart,
		required this.appliedForTag,
	});
}
