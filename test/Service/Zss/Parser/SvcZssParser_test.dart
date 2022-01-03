
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/ZssRule.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Service/Zss/Parser/SvcZssParser_.dart';
import 'package:ezflap/src/Utils/EzError/EzError.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';

void main() {
	group("Testing SvcZssParser", () {
		SvcLogger svcLogger = SvcLogger.i();
		SvcZmlTransformer svcZmlTransformer = SvcZmlTransformer.i();

		ReflectorBootstrapper.initReflectorForTesting();
		svcZmlTransformer.bootstrapDefaultTransformers();

		test("Parse test - invalid XML", () {
			ZssRuleSet zssRuleSet = go("""
				hello world
			""");
			expect(zssRuleSet.arrRules.isEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
		});

		test("Parse test - no <ZSS> tag", () {
			ZssRuleSet zssRuleSet = go("""
				<hello></hello>
			""");
			expect(zssRuleSet.arrRules.isEmpty, true);
			List<EzError> arrErrors = svcLogger.getLoggedErrors();
			expect(arrErrors.length, 1);
			expect(arrErrors[0].message.contains("Expected element <ZSS>, but got <hello>. Tag: <dummy>, merged ZSS: <hello></hello>"), true);
		});

		test("Parse test - no <RULE> tags", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS></ZSS>
			""");
			expect(zssRuleSet.arrRules.isEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
		});

		test("Parse test - no [SEL] attribute", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE>
						<p1->hello</p1->
					</RULE>
				</ZSS>
			""");
			expect(zssRuleSet.arrRules.isEmpty, true);
			List<EzError> arrErrors = svcLogger.getLoggedErrors();
			expect(arrErrors.length, 1);
			expect(arrErrors[0].message.contains("Missing selector for rule: <RULE>"), true);
			expect(arrErrors[0].message.contains("<p1->hello</p1->"), true);
		});

		test("Parse test - no styling parameters", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Container">
					</RULE>
				</ZSS>
			""");
			expect(zssRuleSet.arrRules.isNotEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 1);

			ZssRule rule = zssRuleSet.arrRules[0];
			expect(rule.originalSelector, "Container");
			expect(rule.mapNamedStylingTags.isEmpty, true);
			expect(rule.specificity, 1);
			expect(rule.arrSelectorParts.length, 1);

			ZssSelectorPart selPart = rule.arrSelectorParts[0];
			expect(selPart.isForParameter, false);
			expect(selPart.tagName, "Container");
			expect(selPart.setClasses, null);
			expect(selPart.mapAttrConditions, null);
		});

		test("Parse test - with styling parameters", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Container">
						<p1->hello</p1->
						<p2->world</p2->
					</RULE>
				</ZSS>
			""");
			expect(zssRuleSet.arrRules.isNotEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 1);

			ZssRule rule = zssRuleSet.arrRules[0];
			expect(rule.originalSelector, "Container");
			expect(rule.specificity, 1);
			expect(rule.arrSelectorParts.length, 1);

			ZssSelectorPart selPart = rule.arrSelectorParts[0];
			expect(selPart.isForParameter, false);
			expect(selPart.tagName, "Container");
			expect(selPart.setClasses, null);
			expect(selPart.mapAttrConditions, null);

			expect(rule.mapNamedStylingTags.length, 2);
			expect(rule.mapNamedStylingTags.containsKey("p1"), true);
			expect(rule.mapNamedStylingTags.containsKey("p2"), true);
			expect(rule.mapNamedStylingTags["p1"]!.uid, 1);
			expect(rule.mapNamedStylingTags["p1"]!.tag.name, "p1");
			expect(rule.mapNamedStylingTags["p1"]!.tag.text, "hello");
			expect(rule.mapNamedStylingTags["p2"]!.uid, 2);
			expect(rule.mapNamedStylingTags["p2"]!.tag.name, "p2");
			expect(rule.mapNamedStylingTags["p2"]!.tag.text, "world");
		});

		test("Parse test - complex selector", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Item1 .class1 [attr1=value1] Item2.class2 Item2[attr2=value2] .class3[attr3=value3] Item4.class4[attr4=value4] Item5.class5a.class5b[attr5a=value5a][attr5b=value5b][attr5c] p6- 7-">
					</RULE>
				</ZSS>
			""", true);
			expect(zssRuleSet.arrRules.isNotEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 1);

			ZssRule rule = zssRuleSet.arrRules[0];
			expect(rule.originalSelector, "Item1 .class1 [attr1=value1] Item2.class2 Item2[attr2=value2] .class3[attr3=value3] Item4.class4[attr4=value4] Item5.class5a.class5b[attr5a=value5a][attr5b=value5b][attr5c] p6- 7-");
			expect(rule.specificity, 1307);
			expect(rule.mapNamedStylingTags.length, 0);

			expect(rule.arrSelectorParts.length, 10);
			testSelPart(rule.arrSelectorParts[0], tagName: "Item1");
			testSelPart(rule.arrSelectorParts[1], setClasses: { "class1" });
			testSelPart(rule.arrSelectorParts[2], mapAttrConditions: { "attr1": "value1" });
			testSelPart(rule.arrSelectorParts[3], tagName: "Item2", setClasses: { "class2" });
			testSelPart(rule.arrSelectorParts[4], tagName: "Item2", mapAttrConditions: { "attr2": "value2" });
			testSelPart(rule.arrSelectorParts[5], setClasses: { "class3" }, mapAttrConditions: { "attr3": "value3" });
			testSelPart(rule.arrSelectorParts[6], tagName: "Item4", setClasses: { "class4" }, mapAttrConditions: { "attr4": "value4" });
			testSelPart(rule.arrSelectorParts[7], tagName: "Item5", setClasses: { "class5a", "class5b" }, mapAttrConditions: { "attr5a": "value5a", "attr5b": "value5b", "attr5c": null });
			testSelPart(rule.arrSelectorParts[8], isForParameter: true, tagName: "p6");
			testSelPart(rule.arrSelectorParts[9], isForParameter: true, tagName: ":7");
		});

		test("Parse test - complex styling parameter", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Container">
						<p1->
							<Column>
								<Text>Some text</Text>
							</Column>
						</p1->
					</RULE>
				</ZSS>
			""");
			expect(zssRuleSet.arrRules.isNotEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 1);

			ZssRule rule = zssRuleSet.arrRules[0];
			expect(rule.originalSelector, "Container");
			expect(rule.specificity, 1);
			expect(rule.arrSelectorParts.length, 1);

			ZssSelectorPart selPart = rule.arrSelectorParts[0];
			expect(selPart.isForParameter, false);
			expect(selPart.tagName, "Container");
			expect(selPart.setClasses, null);
			expect(selPart.mapAttrConditions, null);

			expect(rule.mapNamedStylingTags.length, 1);
			expect(rule.mapNamedStylingTags.containsKey("p1"), true);
			expect(rule.mapNamedStylingTags["p1"]!.uid, 1);

			Tag tag = rule.mapNamedStylingTags["p1"]!.tag;
			expect(tag.name, "p1");
			expect(tag.arrUnnamedChildren.length, 1);

			Tag tagColumn = tag.arrUnnamedChildren[0];
			expect(tagColumn.name, "Column");
			expect(tagColumn.mapNamedChildren.length, 1);

			Tag tagNamedParameterForTextTag = tagColumn.mapNamedChildren["children"]!;
			expect(tagNamedParameterForTextTag.name, "children");
			expect(tagNamedParameterForTextTag.arrUnnamedChildren.length, 1);

			Tag tagText = tagNamedParameterForTextTag.arrUnnamedChildren[0];
			expect(tagText.name, "Text");
			expect(tagText.mapNamedChildren.length, 1);
			expect(tagText.mapNamedChildren.containsKey(":0"), true);

			Tag tagNamedParameterForTextContent = tagText.mapNamedChildren[":0"]!;
			expect(tagNamedParameterForTextContent.name, ":0");
			expect(tagNamedParameterForTextContent.arrUnnamedChildren.length, 0);
			expect(tagNamedParameterForTextContent.text, "\"\"\"Some text\"\"\"");
		});

		test("Parse test - selector that does not end with a tag name", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Container .onlyClass">
					</RULE>
				</ZSS>
			""");

			expect(svcLogger.hasLoggedErrors(), true);

			List<EzError> arrErrors = svcLogger.getLoggedErrors();
			expect(arrErrors.length, 1);
			expect(arrErrors[0].message.contains("The last part of the ZSS selector must include a tag name."), true);
			expect(zssRuleSet.arrRules.isEmpty, true);
		});

		test("Parse test - cascade selectors", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Container">
						<RULE SEL="Column">
							<l2a->level2a</l2a->
						</RULE>
						<RULE SEL="Text">
							<l2b->level2b</l2b->
						</RULE>
						<l1->level1</l1->
					</RULE>
				</ZSS>
			""");

			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 3);

			ZssRule container = zssRuleSet.arrRules[0];
			expect(container.arrSelectorParts.length, 1);
			expect(container.arrSelectorParts[0].tagName, "Container");
			expect(container.mapNamedStylingTags.containsKey("l1"), true);
			expect(container.originalSelector, "Container");
			expect(container.specificity, 1);

			ZssRule column = zssRuleSet.arrRules[1];
			expect(column.arrSelectorParts.length, 2);
			expect(column.arrSelectorParts[0].tagName, "Container");
			expect(column.arrSelectorParts[1].tagName, "Column");
			expect(column.mapNamedStylingTags.containsKey("l2a"), true);
			expect(column.originalSelector, "Column");
			expect(column.specificity, 2);

			ZssRule text = zssRuleSet.arrRules[2];
			expect(text.arrSelectorParts.length, 2);
			expect(text.arrSelectorParts[0].tagName, "Container");
			expect(text.arrSelectorParts[1].tagName, "Text");
			expect(text.mapNamedStylingTags.containsKey("l2b"), true);
			expect(text.originalSelector, "Text");
			expect(text.specificity, 2);
		});

		test("Parse test - extended selectors", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="Container">
						<RULE TYPE="extend" SEL=".bold">
							<l2->level2</l2->
							<RULE TYPE="extend" SEL=".italic">
								<l3a->level3a</l3a->
							</RULE>
							<RULE TYPE="extend" SEL="[status]">
								<l3b->level3b</l3b->
							</RULE>
						</RULE>
						<l1->level1</l1->
					</RULE>
				</ZSS>
			""");

			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 4);

			ZssRule container = zssRuleSet.arrRules[0];
			expect(container.arrSelectorParts.length, 1);
			expect(container.arrSelectorParts[0].tagName, "Container");
			expect(container.mapNamedStylingTags.containsKey("l1"), true);
			expect(container.originalSelector, "Container");
			expect(container.specificity, 1);

			ZssRule bold = zssRuleSet.arrRules[1];
			expect(bold.arrSelectorParts.length, 1);
			expect(bold.arrSelectorParts[0].tagName, "Container");
			expect(bold.arrSelectorParts[0].setClasses != null, true);
			expect(bold.arrSelectorParts[0].setClasses!.length, 1);
			expect(bold.arrSelectorParts[0].setClasses!.contains("bold"), true);
			expect(bold.mapNamedStylingTags.containsKey("l2"), true);
			expect(bold.originalSelector, ".bold");
			expect(bold.specificity, 101);

			ZssRule italic = zssRuleSet.arrRules[2];
			expect(italic.arrSelectorParts.length, 1);
			expect(italic.arrSelectorParts[0].tagName, "Container");
			expect(italic.arrSelectorParts[0].setClasses != null, true);
			expect(italic.arrSelectorParts[0].setClasses!.length, 2);
			expect(italic.arrSelectorParts[0].setClasses!.contains("bold"), true);
			expect(italic.arrSelectorParts[0].setClasses!.contains("italic"), true);
			expect(italic.mapNamedStylingTags.containsKey("l3a"), true);
			expect(italic.originalSelector, ".italic");
			expect(italic.specificity, 201);

			ZssRule status = zssRuleSet.arrRules[3];
			expect(status.arrSelectorParts.length, 1);
			expect(status.arrSelectorParts[0].tagName, "Container");
			expect(status.arrSelectorParts[0].setClasses != null, true);
			expect(status.arrSelectorParts[0].setClasses!.length, 1);
			expect(status.arrSelectorParts[0].setClasses!.contains("bold"), true);
			expect(status.arrSelectorParts[0].mapAttrConditions != null, true);
			expect(status.arrSelectorParts[0].mapAttrConditions!.length, 1);
			expect(status.arrSelectorParts[0].mapAttrConditions!.containsKey("status"), true);
			expect(status.arrSelectorParts[0].mapAttrConditions!["status"], null); // because the selector just checks existence
			expect(status.mapNamedStylingTags.containsKey("l3b"), true);
			expect(status.originalSelector, "[status]");
			expect(status.specificity, 201);
		});

		test("Parse test - selectors with quoted attributes", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="[attr1=value1] Item2[attr2=value2] .class3[attr3=value3] Item4.class4[attr4=value4] Item5.class5a.class5b[attr5a=value5a][attr5b=value5b][attr5c]">
					</RULE>

					<RULE SEL="[attr1='value1'] Item2[attr2='value2'] .class3[attr3='value3'] Item4.class4[attr4='value4'] Item5.class5a.class5b[attr5a='value5a'][attr5b='value5b'][attr5c]">
					</RULE>

					<RULE SEL='[attr1="value1"] Item2[attr2="value2"] .class3[attr3="value3"] Item4.class4[attr4="value4"] Item5.class5a.class5b[attr5a="value5a"][attr5b="value5b"][attr5c]'>
					</RULE>
				</ZSS>
			""", true);
			expect(zssRuleSet.arrRules.isNotEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 3);

			int i = 0;
			for (String ch in [ "", "'", "\"" ]) {
				ZssRule rule = zssRuleSet.arrRules[i];
				expect(rule.originalSelector, "[attr1=${ch}value1${ch}] Item2[attr2=${ch}value2${ch}] .class3[attr3=${ch}value3${ch}] Item4.class4[attr4=${ch}value4${ch}] Item5.class5a.class5b[attr5a=${ch}value5a${ch}][attr5b=${ch}value5b${ch}][attr5c]");
				expect(rule.specificity, 1103);
				expect(rule.mapNamedStylingTags.length, 0);

				expect(rule.arrSelectorParts.length, 5);
				testSelPart(rule.arrSelectorParts[0], mapAttrConditions: { "attr1": "${ch}value1${ch}" });
				testSelPart(rule.arrSelectorParts[1], tagName: "Item2", mapAttrConditions: { "attr2": "${ch}value2${ch}" });
				testSelPart(rule.arrSelectorParts[2], setClasses: { "class3" }, mapAttrConditions: { "attr3": "${ch}value3${ch}" });
				testSelPart(rule.arrSelectorParts[3], tagName: "Item4", setClasses: { "class4" }, mapAttrConditions: { "attr4": "${ch}value4${ch}" });
				testSelPart(rule.arrSelectorParts[4], tagName: "Item5", setClasses: { "class5a", "class5b" }, mapAttrConditions: { "attr5a": "${ch}value5a${ch}", "attr5b": "${ch}value5b${ch}", "attr5c": null });

				i++;
			}
		});

		test("Parse test - selectors with quoted attributes with spaces", () {
			ZssRuleSet zssRuleSet = go("""
				<ZSS>
					<RULE SEL="[attr1='value 1'] Item2[attr2='value 2'] .class3[attr3='value 3'] Item4.class4[attr4='value 4'] Item5.class5a.class5b[attr5a='value 5a'][attr5b='value 5b'][attr5c]">
					</RULE>

					<RULE SEL='[attr1="value 1"] Item2[attr2="value 2"] .class3[attr3="value 3"] Item4.class4[attr4="value 4"] Item5.class5a.class5b[attr5a="value 5a"][attr5b="value 5b"][attr5c]'>
					</RULE>
				</ZSS>
			""", true);
			expect(zssRuleSet.arrRules.isNotEmpty, true);
			expect(svcLogger.hasLoggedErrors(), false);
			expect(zssRuleSet.arrRules.length, 2);

			int i = 0;
			for (String ch in [ "'", "\"" ]) {
				ZssRule rule = zssRuleSet.arrRules[i];
				expect(rule.originalSelector, "[attr1=${ch}value 1${ch}] Item2[attr2=${ch}value 2${ch}] .class3[attr3=${ch}value 3${ch}] Item4.class4[attr4=${ch}value 4${ch}] Item5.class5a.class5b[attr5a=${ch}value 5a${ch}][attr5b=${ch}value 5b${ch}][attr5c]");
				expect(rule.specificity, 1103);
				expect(rule.mapNamedStylingTags.length, 0);

				expect(rule.arrSelectorParts.length, 5);
				testSelPart(rule.arrSelectorParts[0], mapAttrConditions: { "attr1": "${ch}value 1${ch}" });
				testSelPart(rule.arrSelectorParts[1], tagName: "Item2", mapAttrConditions: { "attr2": "${ch}value 2${ch}" });
				testSelPart(rule.arrSelectorParts[2], setClasses: { "class3" }, mapAttrConditions: { "attr3": "${ch}value 3${ch}" });
				testSelPart(rule.arrSelectorParts[3], tagName: "Item4", setClasses: { "class4" }, mapAttrConditions: { "attr4": "${ch}value 4${ch}" });
				testSelPart(rule.arrSelectorParts[4], tagName: "Item5", setClasses: { "class5a", "class5b" }, mapAttrConditions: { "attr5a": "${ch}value 5a${ch}", "attr5b": "${ch}value 5b${ch}", "attr5c": null });

				i++;
			}
		});
	});
}

void testSelPart(ZssSelectorPart selPart, {
	bool isForParameter = false,
	String? tagName,
	Set<String>? setClasses,
	Map<String, String?>? mapAttrConditions, // attr name => attr value
}) {
	expect(selPart.isForParameter, isForParameter);
	expect(selPart.tagName, tagName);

	if (selPart.setClasses == null) {
		expect(setClasses, null);
	}

	if (setClasses == null) {
		expect(selPart.setClasses, null);
	}

	if (selPart.setClasses != null && setClasses != null) {
		expect(selPart.setClasses!.containsAll(setClasses), true);
		expect(setClasses.containsAll(selPart.setClasses!), true);
	}

	if (mapAttrConditions == null) {
		expect(selPart.mapAttrConditions, null);
	}

	if (selPart.mapAttrConditions == null) {
		expect(mapAttrConditions, null);
	}

	if (selPart.mapAttrConditions != null && mapAttrConditions != null) {
		for (MapEntry<String, ZssAttrCondition?> kvp in selPart.mapAttrConditions!.entries) {
			expect(mapAttrConditions[kvp.key], kvp.value?.value);
		}
		for (MapEntry<String, String?> kvp in mapAttrConditions.entries) {
			expect(selPart.mapAttrConditions![kvp.key]?.value, kvp.value);
		}
	}
}

ZssRuleSet go(String zss, [ printErrors = false ]) {
	SvcLogger svcLogger = SvcLogger.i();
	SvcZssParser svcZssParser = SvcZssParser.i();
	StylingTag.resetNextUidForTesting();

	Tag tag = Tag(isNamedChildTag: false, parent: null, name: "dummy");
	ZssRuleSet? maybeZssRuleSet;
	svcLogger.invoke(() {
		maybeZssRuleSet = svcZssParser.parse(zss, tag);
	});
	if (printErrors && svcLogger.hasLoggedErrors()) {
		svcLogger.printLoggedErrorsIfNeeded();
	}

	expect(maybeZssRuleSet != null, true);
	return maybeZssRuleSet!;
}