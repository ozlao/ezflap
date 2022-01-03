
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Compiler/SvcZmlCompiler_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Service/Zss/Matcher/SvcZssMatcher_.dart';
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Service/Zss/Parser/SvcZssParser_.dart';
import 'package:ezflap/src/Utils/EzUtils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';

SvcZmlTransformer svcZmlTransformer = SvcZmlTransformer.i();

Future<void> main() async {
	String dir = EzUtils.getDirFromUri(EzUtils.getCallerUri());
	String customEntryPoint = "${dir}/ZmlZssCompilation_test_CustomEntryPoint.dart";
	await ReflectorBootstrapper.initReflectorForTesting(customEntryPoint);
	svcZmlTransformer.bootstrapDefaultTransformers();

	group("Testing ZmlZssCompilation", () {
		test("ZmlZssCompilation test - style nodes", () {
			AstNodeWrapper wrapper = go(
				zml: """
					<Column>
						<Text>
							hello world
						</Text>
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text">
							<textAlign->TextAlign.left</textAlign->
							<locale->
								<Locale>
									<:0->"en"</:0->
								</Locale>
							</locale->
						</RULE>
					</ZSS>
				"""
			);

			expect(wrapper.rootConstructorNode.name, "Column");
			expect(wrapper.mapZssStyleNodes.length, 2);

			// TextAlign
			AstNodeZssStyle styleNode = wrapper.mapZssStyleNodes[1]!;
			expect(styleNode.styleUid, 1);
			expect(styleNode.typeNode.value, "TextAlign?");
			expect(styleNode.styleNode is AstNodeLiteral, true);

			AstNodeLiteral literalNode = styleNode.styleNode as AstNodeLiteral;
			expect(literalNode.value, "TextAlign.left");


			// Locale
			AstNodeZssStyle styleNode2 = wrapper.mapZssStyleNodes[2]!;
			expect(styleNode2.styleUid, 2);
			expect(styleNode2.typeNode.value, "Locale?");
			expect(styleNode2.styleNode is AstNodeConstructor, true);

			AstNodeConstructor constructorNode = styleNode2.styleNode as AstNodeConstructor;
			expect(constructorNode.name, "Locale");
			expect(constructorNode.arrPositionalParams.length, 1);
			expect(constructorNode.arrPositionalParams[0].valueNode is AstNodeLiteral, true);
			expect((constructorNode.arrPositionalParams[0].valueNode as AstNodeLiteral).value, "\"en\"");
		});

		test("ZmlZssCompilation test - simple matching for native widget", () {
			AstNodeWrapper wrapper = go(
				zml: """
					<Text>
						hello world
					</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text">
							<textAlign->TextAlign.left</textAlign->
							<locale->
								<Locale>
									<:0->"en"</:0->
								</Locale>
							</locale->
						</RULE>
					</ZSS>
				"""
			);

			expect(wrapper.rootConstructorNode.name, "Text");
			expect(wrapper.mapZssStyleNodes.length, 2);

			AstNodeConstructor text = wrapper.rootConstructorNode;
			expect(text.mapNamedParams.length, 2);
			expect(text.mapNamedParams.containsKey("textAlign"), true);
			expect(text.mapNamedParams.containsKey("locale"), true);

			AstNodeZssParameterValue textAlign = text.mapNamedParams["textAlign"]!;
			expect(textAlign.arrSelectorNodes?.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes.isEmpty, true);
			expect(textAlign.arrSelectorNodes![0].zssStyleNodeRef, 1);
			expect(textAlign.valueNode is AstNodeNull, true);
		});

		test("ZmlZssCompilation test - simple matching for ezflap widget", () {
			AstNodeWrapper wrapper = go(
				zml: """
					<ReflectorTestExtendEzStatefulWidget />
				""",

				zss: """
					<ZSS>
						<RULE SEL="ReflectorTestExtendEzStatefulWidget">
							<textAlign->TextAlign.left</textAlign->
							<hello->"nihao"</hello->
						</RULE>
					</ZSS>
				""",

				printErrors: true,
			);

			expect(wrapper.rootConstructorNode.name, "ReflectorTestExtendEzStatefulWidget");
			expect(wrapper.mapZssStyleNodes.length, 2);

			AstNodeConstructor text = wrapper.rootConstructorNode;
			expect(text.mapNamedParams.length, 2);
			expect(text.mapNamedParams.containsKey("textAlign"), true);
			expect(text.mapNamedParams.containsKey("hello"), true);

			AstNodeZssParameterValue textAlign = text.mapNamedParams["textAlign"]!;
			expect(textAlign.arrSelectorNodes?.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes.isEmpty, true);
			expect(textAlign.arrSelectorNodes![0].zssStyleNodeRef, 1);
			expect(textAlign.valueNode is AstNodeLiteral, true);
			expect((textAlign.valueNode as AstNodeLiteral).value, "TextAlign.end");
		});

		test("ZmlZssCompilation test - conditional matching with classes", () {
			AstNodeWrapper wrapper = go(
				zml: """
					<Text z-attr:class="myClasses">
						hello world
					</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text.class1">
							<textAlign->TextAlign.left</textAlign->
							<locale->
								<Locale>
									<:0->"en"</:0->
								</Locale>
							</locale->
						</RULE>
					</ZSS>
				"""
			);

			expect(wrapper.rootConstructorNode.name, "Text");
			expect(wrapper.mapZssStyleNodes.length, 2);

			AstNodeConstructor text = wrapper.rootConstructorNode;
			expect(text.mapNamedParams.length, 2);
			expect(text.mapNamedParams.containsKey("textAlign"), true);
			expect(text.mapNamedParams.containsKey("locale"), true);

			AstNodeZssParameterValue textAlign = text.mapNamedParams["textAlign"]!;
			expect(textAlign.arrSelectorNodes?.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrExpectedClasses?.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrExpectedClasses!.contains("class1"), true);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].actualClassesNode?.value, "myClasses");
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrZssConditionAttrNodes, null);
			expect(textAlign.valueNode is AstNodeNull, true);
		});

		test("ZmlZssCompilation test - conditional matching with attributes", () {
			AstNodeWrapper wrapper = go(
				zml: """
					<Text z-attr:hello="myHello">
						hello world
					</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text[hello=world]">
							<textAlign->TextAlign.left</textAlign->
							<locale->
								<Locale>
									<:0->"en"</:0->
								</Locale>
							</locale->
						</RULE>
					</ZSS>
				"""
			);

			expect(wrapper.rootConstructorNode.name, "Text");
			expect(wrapper.mapZssStyleNodes.length, 2);

			AstNodeConstructor text = wrapper.rootConstructorNode;
			expect(text.mapNamedParams.length, 2);
			expect(text.mapNamedParams.containsKey("textAlign"), true);
			expect(text.mapNamedParams.containsKey("locale"), true);

			AstNodeZssParameterValue textAlign = text.mapNamedParams["textAlign"]!;
			expect(textAlign.arrSelectorNodes?.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrExpectedClasses, null);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].actualClassesNode, null);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrZssConditionAttrNodes?.length, 1);
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrZssConditionAttrNodes![0].expectedValue, "world");
			expect(textAlign.arrSelectorNodes![0].arrConditionNodes[0].arrZssConditionAttrNodes![0].actualValueLiteralNode!.value, "myHello");
			expect(textAlign.valueNode is AstNodeNull, true);
		});

		test("ZmlZssCompilation test - conditional matching for custom with attributes and default", () {
			AstNodeWrapper wrapper = go(
				zml: """
					<ReflectorTestExtendEzStatefulWidget z-attr:class="myClasses">
						hello world
					</ReflectorTestExtendEzStatefulWidget>
				""",

				zss: """
					<ZSS>
						<RULE SEL="ReflectorTestExtendEzStatefulWidget.class1">
							<textAlign->TextAlign.left</textAlign->
							<hello->"good morning"</hello->
						</RULE>
					</ZSS>
				"""
			);

			expect(wrapper.rootConstructorNode.name, "ReflectorTestExtendEzStatefulWidget");
			expect(wrapper.mapZssStyleNodes.length, 2);

			AstNodeConstructor widget = wrapper.rootConstructorNode;
			expect(widget.mapNamedParams.length, 2);
			expect(widget.mapNamedParams.containsKey("textAlign"), true);
			expect(widget.mapNamedParams.containsKey("hello"), true);

			AstNodeZssParameterValue hello = widget.mapNamedParams["hello"]!;
			expect(hello.arrSelectorNodes?.length, 1);
			expect(hello.arrSelectorNodes![0].arrConditionNodes.length, 1);
			expect(hello.arrSelectorNodes![0].arrConditionNodes[0].arrExpectedClasses?.length, 1);
			expect(hello.arrSelectorNodes![0].arrConditionNodes[0].arrExpectedClasses!.contains("class1"), true);
			expect(hello.arrSelectorNodes![0].arrConditionNodes[0].actualClassesNode?.value, "myClasses");
			expect(hello.arrSelectorNodes![0].arrConditionNodes[0].arrZssConditionAttrNodes, null);
			expect(hello.valueNode is AstNodeLiteral, true);
			expect((hello.valueNode as AstNodeLiteral).value, "\"bye\"");
		});
	});
}

void testParam(Tag tag, String name, {
	required int ruleIdx,
	required int uid,
	required int numSelectorParts,
}) {
	expect(tag.mapZssToParams.containsKey(name), true);
	expect(tag.mapZssToParams[name]!.arrApplicableRules.length > ruleIdx, true);
	expect(tag.mapZssToParams[name]!.arrApplicableRules[ruleIdx].styleRootTag.uid, uid);
	expect(tag.mapZssToParams[name]!.arrApplicableRules[ruleIdx].styleRootTag.tag.name, name);
	expect(tag.mapZssToParams[name]!.arrApplicableRules[ruleIdx].arrApplicableSelectorParts.length, numSelectorParts);
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

AstNodeWrapper go({ required String zml, required String zss, bool printErrors = false }) {
	SvcLogger svcLogger = SvcLogger.i();
	SvcZmlParser svcZmlParser = SvcZmlParser.i();
	SvcZssParser svcZssParser = SvcZssParser.i();
	SvcZssMatcher svcZssMatcher = SvcZssMatcher.i();
	SvcZmlCompiler svcZmlCompiler = SvcZmlCompiler.i();
	StylingTag.resetNextUidForTesting();

	Tag? transTag;
	AstNodeWrapper? wrapper;
	svcLogger.invoke(() {
		Tag? maybeTag = svcZmlParser.tryParse(zml);
		expect(maybeTag != null, true);

		transTag = svcZmlTransformer.transform(maybeTag!);

		ZssRuleSet? maybeZssRuleSet = svcZssParser.parse(zss, transTag!);
		expect(maybeZssRuleSet != null, true);

		svcZssMatcher.matchZssToTags(transTag!, maybeZssRuleSet!);
		wrapper = svcZmlCompiler.tryGenerateAst(transTag!);
		expect(wrapper != null, true);
	});

	if (printErrors && svcLogger.hasLoggedErrors()) {
		svcLogger.printLoggedErrorsIfNeeded();
	}

	return wrapper!;
}