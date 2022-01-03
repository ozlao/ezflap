
import 'package:ezflap/src/Service/Zss/Parser/Rule/ZssRule.dart';
import 'package:meta/meta.dart';

@immutable
class ZssRuleSet {
	final List<ZssRule> arrRules;

	ZssRuleSet(this.arrRules);

	void addRulesFromRuleSet(ZssRuleSet other) {
		this.arrRules.addAll(other.arrRules);
	}

	ZssRuleSet concat(ZssRuleSet? other) {
		ZssRuleSet newRuleSet = new ZssRuleSet(this.arrRules.toList());
		if (other != null) {
			newRuleSet.addRulesFromRuleSet(other);
		}
		return newRuleSet;
	}
}
