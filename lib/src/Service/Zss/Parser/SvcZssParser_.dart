
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/EzServiceBase.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/ZssRule.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';
import 'package:ezflap/src/Utils/Singleton/Singleton.dart';
import 'package:xml/xml.dart';

class SvcZssParser extends EzServiceBase {
	static SvcZssParser i() { return $Singleton.get(() => SvcZssParser()); }

	SvcLogger get _svcLogger => SvcLogger.i();
	SvcZmlParser get _svcZmlParser => SvcZmlParser.i();
	SvcZmlTransformer get _svcZmlTransformer => SvcZmlTransformer.i();

	static const String _COMPONENT = "SvcZssParser";

	static const String ZSS_TAG_NAME = "ZSS";

	static const String _RULE_ATTR_KEY_SEL = "SEL";
	static const String _RULE_ATTR_KEY_TYPE = "TYPE";

	static const String _RULE_TYPE_EXTEND = "extend";

	Tag? _curForTag;
	String? _curZss;

	ZssRuleSet? parse(String zss, Tag forTag) {
		this._curZss = zss;
		this._curForTag = forTag;
		
		String wrappedZss = "<_wrapper>${zss}</_wrapper>";
		XmlDocument xDoc;
		try {
			xDoc = XmlDocument.parse(wrappedZss);
		}
		catch (ex) {
			this._log("Failed to parse merged ZSS.");
			return null;
		}

		List<ZssRule> arrRules = [ ];
		this._parseZssWrappers(xDoc.rootElement.children, arrRules);
		ZssRuleSet ruleSet = ZssRuleSet(arrRules);

		return ruleSet;
	}

	void _parseZssWrappers(Iterable<XmlNode> iterElements, List<ZssRule> arrRules) {
		for (XmlNode xZssElement in iterElements) {
			if (xZssElement is XmlElement) {
				if (xZssElement.name.local != ZSS_TAG_NAME) {
					this._log("Expected element <${ZSS_TAG_NAME}>, but got <${xZssElement.name.local}>.");
					continue;
				}

				this._parseRules(xZssElement.children, arrRules, null);
			}
		}
	}

	void _parseRules(Iterable<XmlNode> iterElements, List<ZssRule> arrRules, ZssRule? parentRule) {
		for (XmlNode xRule in iterElements) {
			if (xRule is XmlElement) {
				String name = xRule.name.local;
				if (name.startsWith("_")) {
					continue;
				}

				if (name == "RULE") {
					this._parseRule(xRule, arrRules, parentRule);
				}
				else {
					this._log("Expected element <RULE>, but got <${name}>.");
				}
			}
		}
	}
	
	void _parseRule(XmlElement xRule, List<ZssRule> arrRules, ZssRule? parentRule) {
		String? selector = xRule.getAttribute(_RULE_ATTR_KEY_SEL);
		if (selector == null) {
			this._log("Missing selector for rule: ${xRule}.");
			return;
		}

		List<ZssSelectorPart> arrSelectorParts = [ ];
		if (parentRule != null) {
			// copy selector parts from parent rule
			arrSelectorParts.addAll(parentRule.arrSelectorParts);
		}

		Iterable<ZssSelectorPart>? iterSelfSelectorParts = this._parseSelector(selector);
		if (iterSelfSelectorParts == null) {
			this._log("No selectors found for rule: ${xRule}, in selector: [${selector}].");
			return;
		}

		if (parentRule != null && xRule.getAttribute(_RULE_ATTR_KEY_TYPE) == _RULE_TYPE_EXTEND) {
			// this rule extends its parent rule, so we need to merge the
			// parent's last selectorPart with our first selectorPart
			ZssSelectorPart merged = arrSelectorParts.last.mergeFromIntoNew(iterSelfSelectorParts.first);
			arrSelectorParts.last = merged;
			iterSelfSelectorParts = iterSelfSelectorParts.skip(1);
		}

		arrSelectorParts.addAll(iterSelfSelectorParts);
		if (!this._verifyLastSelectorPart(arrSelectorParts.last, selector)) {
			return;
		}

		Iterable<XmlElement> iterElements = xRule.children.whereType<XmlElement>().asIterableOf<XmlElement>();
		Iterable<XmlElement> iterNamedStylingElements = iterElements.where((x) => x.name.local != "RULE");
		Map<String, StylingTag> mapNamedStylingTags = this._processStylingElements(iterNamedStylingElements);

		ZssRule rule = ZssRule(
			arrSelectorParts: arrSelectorParts,
			mapNamedStylingTags: mapNamedStylingTags,
			originalSelector: selector,
		);
		arrRules.add(rule);

		Iterable<XmlElement> iterSubRuleElements = iterElements.where((x) => x.name.local == "RULE");
		this._parseRules(iterSubRuleElements, arrRules, rule);
	}

	Map<String, StylingTag> _processStylingElements(Iterable<XmlElement> iterNamedStylingElements) {
		Map<String, StylingTag> map = { };
		for (XmlElement xElement in iterNamedStylingElements) {
			if (this._svcZmlParser.isTagCommentedOut(xElement)) {
				continue;
			}

			Tag? tag = this._svcZmlParser.makeTag(xElement, null);
			if (tag == null) {
				this._log("Failed to parse ZML tag: ${xElement}.");
				continue;
			}
			Tag transformedTag = this._svcZmlTransformer.transform(tag);

			String name = transformedTag.name;
			map[name] = StylingTag(transformedTag);
		}
		return map;
	}

	List<ZssSelectorPart>? _parseSelector(String selector) {
		Iterable<String>? iterParts = selector.splitAndTrim(" ", respectQuotes: true);
		if (iterParts == null) {
			return null;
		}

		List<ZssSelectorPart?> arrSelectorPartsNullable = iterParts.map((x) => this._parseSelectorPart(x)).toList();
		if (arrSelectorPartsNullable.any((x) => x == null)) {
			return null;
		}

		List<ZssSelectorPart> arrSelectorParts = arrSelectorPartsNullable.denull().toList(growable: false);

		return arrSelectorParts;
	}

	bool _verifyLastSelectorPart(ZssSelectorPart selectorPart, String selector) {
		if (selectorPart.tagName == null) {
			this._svcLogger.logErrorFrom(_COMPONENT, "The last part of the ZSS selector must include a tag name. Failed selector: ${selector}");
			return false;
		}
		return true;
	}

	ZssSelectorPart? _parseSelectorPart(String selectorPart) {
		RegExp regexp = RegExp(
			r"""(^[a-zA-Z0-9]+-?)|(\.[a-zA-Z0-9]+)|(\[[a-zA-Z0-9]+(=.+?)?\])|(\[[a-zA-Z0-9]+(=".+?")?\])|(\[[a-zA-Z0-9]+(='.+?')?\])""",
			caseSensitive: false,
			multiLine: false,
		);

		ZssSelectorPart part = ZssSelectorPart();
		Iterable<RegExpMatch> matches = regexp.allMatches(selectorPart);
		for (RegExpMatch match in matches) {
			String? item = match.firstGroupMatch();
			if (item == null || item.isEmpty) {
				continue;
			}

			this._tryParseSelectorPartTagName(item, part);
			this._tryParseSelectorPartClass(item, part);
			this._tryParseSelectorPartAttr(item, part);
		}

		if (part.mapAttrConditions == null && part.tagName == null && part.setClasses == null) {
			this._log("Encountered an empty selector part: [${selectorPart}].");
			return null;
		}

		return part;
	}

	void _tryParseSelectorPartTagName(String text, ZssSelectorPart part) {
		if (text[0] == "." || text[0] == "[") {
			return;
		}

		if (text.lastChar() == "-") {
			part.isForParameter = true;
			text = text.substring(0, text.length - 1);

			bool isNumeric = (int.tryParse(text) != null);
			if (isNumeric) {
				// we need to add a colon prefix because this is how the name
				// is stored in Tag. we intentionally avoid having the colon in
				// the selector because we may want to use it for other purposes
				// in the future, and it's probably not worth it to "waste" it
				// on supporting positional parameters in selectors (which will
				// probably be very rare...)
				text = ":${text}";
			}
		}
		part.tagName = text;
	}

	void _tryParseSelectorPartClass(String text, ZssSelectorPart part) {
		if (text[0] != ".") {
			return;
		}
		part.setClasses ??= Set<String>();
		part.setClasses!.add(text.substring(1));
	}

	void _tryParseSelectorPartAttr(String text, ZssSelectorPart part) {
		if (text[0] != "[") {
			return;
		}
		part.mapAttrConditions ??= Map<String, ZssAttrCondition?>();
		int posEqual = text.indexOf("=");
		if (posEqual == -1) {
			// no equality sign. we just need to confirm existence
			String attrName = text.substring(1, text.length - 1);
			part.mapAttrConditions![attrName] = null;
			return;
		}

		String attrName = text.substring(1, posEqual);
		String attrValue = text.substring(posEqual + 1, text.length - 1);
		part.mapAttrConditions![attrName] = ZssAttrCondition(attrName, attrValue);
	}

	void _log(String message) {
		this._svcLogger.logErrorFrom(_COMPONENT, "${message} Tag: ${this._curForTag}, merged ZSS: ${this._curZss?.trim()}");
	}
}