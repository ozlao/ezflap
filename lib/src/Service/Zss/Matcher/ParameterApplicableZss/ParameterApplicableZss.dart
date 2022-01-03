
import 'package:ezflap/src/Service/Zss/Matcher/ApplicableZssRule/ApplicableZssRule.dart';

class ParameterApplicableZss {
	// NOT sorted by specificity
	final List<ApplicableZssRule> arrApplicableRules;

	ParameterApplicableZss({
		required this.arrApplicableRules,
	});
}
