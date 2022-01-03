
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Parser/Mustache/SvcMustacheParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zss/Matcher/ApplicableZssRule/ApplicableZssRule.dart';
import 'package:ezflap/src/Service/Zss/Matcher/ApplicableZssSelectorPart/ApplicableZssSelectorPart.dart';
import 'package:ezflap/src/Service/Zss/Matcher/ParameterApplicableZss/ParameterApplicableZss.dart';
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/ZssRule.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

enum EMatchType {
	certainMatch,
	potentialMatch,
	noMatch,
}

class _MatchData {
	late EMatchType matchType;

	// holds the conditions that need to be satisfied for the SelectorPart to
	// match a tag. null if there can be no match, or if the match is certain
	// and there are no conditions to be applied.
	final ApplicableZssSelectorPart? applicableZssSelectorPart;

	// the remaining classes to match for the SelectorPart during runtime.
	// this is used specifically when trying to match classes, and contains the
	// classes that remain after matching all hardcoded classes (i.e. all
	// classes that are provided in tag.attrClasses).
	final Set<String>? setClassesToMatch;
	
	// the remaining attributes to match for the SelectorPart during runtime.
	// this is used specifically when trying to match attributes, and contains
	// the attributes (and their conditions) that remain after matching all
	// hardcoded attributes, and unconditional (i.e. existence) attributes.
	final Map<String, ZssAttrCondition>? mapAttrsToMatch;
	

	_MatchData({
		required this.matchType,
		this.setClassesToMatch,
		this.mapAttrsToMatch,
		this.applicableZssSelectorPart,
	});

	factory _MatchData.noMatch() {
		return _MatchData(matchType: EMatchType.noMatch);
	}

	factory _MatchData.certainMatch() {
		return _MatchData(matchType: EMatchType.certainMatch);
	}
	
	factory _MatchData.potentialMatch(Set<String>? setClassesToMatch, Map<String, ZssAttrCondition>? mapAttrsToMatch) {
		return _MatchData(
			matchType: EMatchType.potentialMatch,
			setClassesToMatch: setClassesToMatch,
			mapAttrsToMatch: mapAttrsToMatch,
		);
	}
	
	bool isCertainMatch() {
		return (this.matchType == EMatchType.certainMatch);
	}
	
	bool isNoMatch() {
		return (this.matchType == EMatchType.noMatch);
	}
	
	bool isPotentialMatch() {
		return (this.matchType == EMatchType.potentialMatch);
	}

	@override
	String toString() {
		return "MatchData: ${this.matchType.toString()}";
	}
}

class SvcZssMatcher extends EzServiceBase {
	static SvcZssMatcher i() { return Singleton.get(() => SvcZssMatcher()); }

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcMustacheParser get _svcMustacheParser => SvcMustacheParser.i();

	// TODO: discard rules that are 100% overshadowed by more specific rules
	void matchZssToTags(Tag rootTag, ZssRuleSet ruleSet) {
		List<Tag> arrTags = rootTag.collectDescendantsAndSelf();
		for (Tag tag in arrTags) {
			this._matchZssToTag(tag, ruleSet);
		}
	}

	void _matchZssToTag(Tag tag, ZssRuleSet ruleSet) {
		List<ZssRule> arrSortedRules = this._getRulesSortedByOrderAndSpecificity(ruleSet);
		for (ZssRule rule in arrSortedRules) {
			if (rule.arrSelectorParts.isEmpty) {
				// could happen if ZSS has mistakes in it. in such case -
				// errors were already printed, so we just skip it.
				continue;
			}

			this._applyRuleToTagIfNeeded(tag, rule);
		}
	}

	List<ZssRule> _getRulesSortedByOrderAndSpecificity(ZssRuleSet ruleSet) {
		Map<int, List<ZssRule>> map = { };
		for (ZssRule rule in ruleSet.arrRules) {
			int specificity = rule.specificity;
			if (!map.containsKey(specificity)) {
				map[specificity] = [ ];
			}
			map[specificity]!.add(rule);
		}

		List<ZssRule> arrSortedRules = [ ];
		Map<int, List<ZssRule>> mapSorted = map.sortByKeysNumeric((int specificity) => specificity);
		for (MapEntry<int, List<ZssRule>> kvp in mapSorted.entries) {
			arrSortedRules.addAll(kvp.value);
		}

		return arrSortedRules;
	}

	void _applyRuleToTagIfNeeded(Tag tag, ZssRule rule) {
		// used to build the potentially-matching selector parts. will be
		// discarded if eventually the rule cannot match the tag.
		List<ApplicableZssSelectorPart> arrApplicableSelectorParts = [ ];
		
		Tag? curTag = tag;
		Iterable<ZssSelectorPart> iterRev = rule.arrSelectorParts.reversed;
		for (ZssSelectorPart selectorPart in iterRev) {
			bool foundMatch = false;
			while (curTag != null) {
				_MatchData matchData = this._tryMatchSelectorPartForTag(selectorPart, curTag);
				if (matchData.isNoMatch()) {
					if (curTag == tag) {
						// the last selectorPart must much the current tag (because
						// if it doesn't, even if it matches the current tag's
						// parent - it wouldn't apply for the current tag).
						// so - we can skip the entire rule.
						return;
					}

					// no match. try parent tag
					curTag = curTag.parent;
					continue;
				}

				if (matchData.isPotentialMatch()) {
					// a potential match. apply to arrApplicableSelectorParts
					// (so that the potential-match conditions can be tested
					// against evaluated values in runtime).
					this._addApplicableSelectorPartsToTag(
						arrApplicableSelectorParts: arrApplicableSelectorParts,
						tag: curTag,
						templateSelectorPart: selectorPart,
						matchData: matchData,
					);
				}
				
				// advance to next selector
				foundMatch = true;
				
				// and to the parent tag
				curTag = curTag.parent;
				
				break;
			}

			if (!foundMatch) {
				// if we got here without a match then it means that no tag
				// in the hierarchy matched the current selectorPart and
				// therefore the rule doesn't match.
				return;
			}
		}

		// if we got here then all selectorParts have been matched and the
		// rule matches.
		this._applyZssConditionsAndStylingToTag(tag, rule, arrApplicableSelectorParts);
	}
	
	void _addApplicableSelectorPartsToTag({
		required List<ApplicableZssSelectorPart> arrApplicableSelectorParts,
		required Tag tag,
		required ZssSelectorPart templateSelectorPart,
		required _MatchData matchData
	}) {
		assert(matchData.isPotentialMatch(), "only need to add applicable selector parts for potential matches.");
		assert(!tag.isNamedChildTag, "named child tags cannot be potentially matched; they yield either a certain match, or no match.");

		ZssSelectorPart selectorPart = ZssSelectorPart()
			..tagName = tag.name
			..isForParameter = false
			..setClasses = matchData.setClassesToMatch
			..mapAttrConditions = matchData.mapAttrsToMatch
		;

		ApplicableZssSelectorPart applicableZssSelectorPart = ApplicableZssSelectorPart(
			selectorPart: selectorPart,
			appliedForTag: tag,
		);

		arrApplicableSelectorParts.add(applicableZssSelectorPart);
	}

	void _applyZssConditionsAndStylingToTag(Tag tag, ZssRule rule, List<ApplicableZssSelectorPart> arrApplicableSelectorParts) {
		// we sort the named styling tags first to ensure that positional
		// styling tags are listed in the right order. this is important for
		// the AST generation, because positional nodes are stored in a list,
		// and we need to add them in order. also, being able to rely on the
		// order allows us to easily log an error if a positional parameter is
		// missing (e.g. we can't provide positional parameter #2 in a style if
		// positional parameter #1 is not provided (i.e. in another style, or
		// in the ZML)).
		Map<String, StylingTag> mapSorted = rule.mapNamedStylingTags.sortByKeysString((String key) {
			int? idx = int.tryParse(key);
			if (idx == null) {
				// we are dealing with a named parameter, just return as-is.
				return key;
			}
			else {
				// we are dealing with a positional parameter. pad it, to make
				// sure it's sorted correctly (e.g. so that 2 will come after 10)
				return key.padLeft(3, "0");
			}
		});

		for (MapEntry<String, StylingTag> kvp in mapSorted.entries) {
			String styleKey = kvp.key;
			ApplicableZssRule applicableZssRule = ApplicableZssRule(
				arrApplicableSelectorParts: arrApplicableSelectorParts,
				styleRootTag: kvp.value,
				specificity: rule.specificity,
			);
			
			if (!tag.mapZssToParams.containsKey(styleKey)) {
				tag.mapZssToParams[styleKey] = ParameterApplicableZss(arrApplicableRules: [ ]);
			}
			
			ParameterApplicableZss parameterApplicableZss = tag.mapZssToParams[styleKey]!;

			if (this._isApplicableZssRuleCertain(applicableZssRule)) {
				// this rule will always be applied, so we can discard the rules
				// that came before it.
				parameterApplicableZss.arrApplicableRules.clear();
			}

			parameterApplicableZss.arrApplicableRules.add(applicableZssRule);
		}
	}

	// returns true if applicableZssRule have no conditions (i.e. if it has
	// been fully satisfied with static data and doesn't need to be re-evaluated
	// in runtime).
	bool _isApplicableZssRuleCertain(ApplicableZssRule applicableZssRule) {
		if (applicableZssRule.arrApplicableSelectorParts.isEmpty) {
			return true;
		}

		bool hasRuntimeConditions = applicableZssRule.arrApplicableSelectorParts.any((ApplicableZssSelectorPart applicableSelectorPart) {
			ZssSelectorPart selectorPart = applicableSelectorPart.selectorPart;
			if (selectorPart.setClasses != null) {
				return true;
			}
			if (selectorPart.mapAttrConditions != null) {
				return true;
			}
			return false;
		});

		return !hasRuntimeConditions;
	}

	_MatchData _tryMatchSelectorPartForTag(ZssSelectorPart selectorPart, Tag tag) {
		if (!this._doesSelectorPartMatchTagName(selectorPart, tag)) {
			return _MatchData.noMatch();
		}

		if (selectorPart.isForParameter) {
			// for named parameters we only need to check the name
			return _MatchData.certainMatch();
		}

		// if we got here then it means that the tag is not a named child tag,
		// and the name matches (or the selectorPart doesn't specify a name).
		
		// match classes
		_MatchData matchClasses = this._tryMatchSelectorPartByClasses(selectorPart, tag);
		if (matchClasses.matchType == EMatchType.noMatch) {
			// classes don't match. nothing further to do
			return _MatchData.noMatch();
		}

		// match attributes
		_MatchData matchAttrs = this._tryMatchSelectorPartByAttributes(selectorPart, tag);
		if (matchAttrs.matchType == EMatchType.noMatch) {
			// attributes don't match. nothing further to do
			return _MatchData.noMatch();
		}
		
		// check if both classes and attributes are a certain match
		if (matchClasses.isCertainMatch() && matchAttrs.isCertainMatch()) {
			return _MatchData.certainMatch();
		}

		// we have a potential match. assemble the information we collected
		return _MatchData.potentialMatch(matchClasses.setClassesToMatch, matchAttrs.mapAttrsToMatch);
	}

	bool _doesSelectorPartMatchTagName(ZssSelectorPart selectorPart, Tag tag) {
		if (selectorPart.isForParameter != tag.isNamedChildTag) {
			return false;
		}

		if (selectorPart.tagName == null) {
			return true;
		}

		if (selectorPart.tagName == tag.name) {
			return true;
		}

		return false;
	}

	_MatchData _tryMatchSelectorPartByClasses(ZssSelectorPart selectorPart, Tag tag) {
		if (selectorPart.setClasses == null || selectorPart.setClasses!.isEmpty) {
			return _MatchData.certainMatch();
		}

		String? hardcodedClasses = tag.stringAttrClass;
		String? evaluatedClasses = tag.attrClass;
		if (hardcodedClasses == null && evaluatedClasses == null) {
			return _MatchData.noMatch();
		}

		// compare hardcoded
		Set<String>? setRemainingSelectorClasses = null;
		setRemainingSelectorClasses = this._getSelectorPartClassesThatAreMissingInTagHardcodedClasses(hardcodedClasses, selectorPart.setClasses!);
		if (setRemainingSelectorClasses.isEmpty) {
			return _MatchData.certainMatch();
		}

		// if there are only hardcoded classes, and we got here - then there is
		// no match
		if (evaluatedClasses == null) {
			return _MatchData.noMatch();
		}

		// we will need to compare the remaining classes to the evaluated
		// classes in runtime.
		return _MatchData(
			matchType: EMatchType.potentialMatch,
			setClassesToMatch: setRemainingSelectorClasses,
		);
	}

	Set<String> _getSelectorPartClassesThatAreMissingInTagHardcodedClasses(String? tagClasses, Set<String> setSelectorClasses) {
		if (setSelectorClasses.length == 0) {
			return { };
		}

		List<String>? arrTagClasses;
		if (tagClasses != null) {
			arrTagClasses = tagClasses.splitAndTrim(" ");
		}

		if (arrTagClasses == null) {
			return setSelectorClasses;
		}

		Set<String> setTagClasses = arrTagClasses.toSet();
		Set<String> setRemainingClasses = setSelectorClasses.difference(setTagClasses);

		return setRemainingClasses;
	}

	_MatchData _tryMatchSelectorPartByAttributes(ZssSelectorPart selectorPart, Tag tag) {
		if (selectorPart.mapAttrConditions == null) {
			return _MatchData.certainMatch();
		}

		Map<String, ZssAttrCondition?>? mapRemainingAttrs = this._matchHardcodedAttrsAndGetRemaining(selectorPart, tag);
		if (mapRemainingAttrs == null) {
			// there's no match!
			return _MatchData.noMatch();
		}

		if (mapRemainingAttrs.isEmpty) {
			// nothing left to match!
			return _MatchData.certainMatch();
		}

		Map<String, ZssAttrCondition>? mapPotentials = this._matchEvaluatedAttrsAndGetPotentials(mapRemainingAttrs, tag);
		if (mapPotentials == null) {
			// there's no match! (some required attribute is missing altogether
			// from the Tag's attributes).
			return _MatchData.noMatch();
		}
		
		if (mapPotentials.isEmpty) {
			// there's a certain match, because there are no "potentially-
			// matching" attributes.
			return _MatchData.certainMatch();
		}
		
		return _MatchData(
			matchType: EMatchType.potentialMatch,
			mapAttrsToMatch: mapPotentials,
		);
	}

	// returns null if a SelectorPart conditional attr has no corresponding
	// evaluated attribute.
	// returns all SelectorPart attr conditions that depend on a value and not
	// just on existence (because existence conditions can be tested against
	// evaluated attributes in compile time, because an evaluated attribute
	// always "exists", regardless of its value in runtime).
	Map<String, ZssAttrCondition>? _matchEvaluatedAttrsAndGetPotentials(Map<String, ZssAttrCondition?> mapAttrConditions, Tag tag) {
		Map<String, String> mapTagEvaluatedAttrs = {
			...tag.mapZAttrs,
			...tag.mapStrings.where((x) => this._svcMustacheParser.doesStringHaveMustache(x)),
		};

		Map<String, ZssAttrCondition> mapPotentialAttrs = { };
		for (MapEntry<String, ZssAttrCondition?> kvp in mapAttrConditions.entries) {
			if (!mapTagEvaluatedAttrs.containsKey(kvp.key)) {
				// the evaluated attributes don't contain this conditional
				// attribute.
				return null;
			}

			// a matching evaluated attribute was found!
			if (kvp.value == null) {
				// the condition only cares about existence. so we always match
				// (i.e. the match does not depend on the attribute's evaluated
				// value in runtime). proceed to the next attribute.
				continue;
			}

			// the values may match, but we'll only know this in real time
			mapPotentialAttrs[kvp.key] = kvp.value!;
		}

		return mapPotentialAttrs;
	}


	// returns null if a SelectorPart conditional attr has a corresponding
	// hardcoded attr, but their values don't match.
	Map<String, ZssAttrCondition?>? _matchHardcodedAttrsAndGetRemaining(ZssSelectorPart selectorPart, Tag tag) {
		Map<String, String> mapTagHardcodedAttrs = {
			...tag.mapStrings.where((x) => !this._svcMustacheParser.doesStringHaveMustache(x)),
		};

		Map<String, ZssAttrCondition?> mapRemainingAttrs = { };
		for (MapEntry<String, ZssAttrCondition?> kvp in selectorPart.mapAttrConditions!.entries) {
			ZssAttrCondition? zssAttrCondition = kvp.value;
			if (!mapTagHardcodedAttrs.containsKey(kvp.key)) {
				// the hardcoded attributes don't contain this conditional
				// attribute; put it aside for comparing it with evaluated
				// attributes later.
				mapRemainingAttrs[kvp.key] = zssAttrCondition;
				continue;
			}

			// a matching hardcoded attribute was found!
			if (zssAttrCondition == null) {
				// the condition only cares about existence. so we match.
				// proceed to the next attribute.
				continue;
			}

			// do the values match?
			if (!zssAttrCondition.isHardcoded()) {
				// this selector part is not hardcoded (e.g. [color=Colors.red])
				// so we don't compare it.
				continue;
			}

			String tagAttrValue = mapTagHardcodedAttrs[kvp.key]!;
			if (tagAttrValue == kvp.value!.getUnquotedValue()) {
				// the values match. proceed to the next attribute.
				continue;
			}

			// if we get here then the condition value for the attribute does
			// not match the hardcoded value provided in the tag. this means
			// that the SelectorPart doesn't match.
			return null;
		}

		return mapRemainingAttrs;
	}
}