
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Service/Zss/Matcher/SvcZssMatcher_.dart';
import 'package:ezflap/src/Service/Zss/Parser/AttrCondition/ZssAttrCondition.dart';
import 'package:ezflap/src/Service/Zss/Parser/Rule/StylingTag/StylingTag.dart';
import 'package:ezflap/src/Service/Zss/Parser/RuleSet/ZssRuleSet.dart';
import 'package:ezflap/src/Service/Zss/Parser/SelectorPart/ZssSelectorPart.dart';
import 'package:ezflap/src/Service/Zss/Parser/SvcZssParser_.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';

SvcZmlTransformer svcZmlTransformer = SvcZmlTransformer.i();

void main() {
	group("Testing SvcZssMatcher", () {
		ReflectorBootstrapper.initReflectorForTesting();
		svcZmlTransformer.bootstrapDefaultTransformers();


		test("Match test - test 1", () {
			Tag tag = go(
				zml: """
					<Column></Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Container">
							<p1->hello</p1->
							<p2->world</p2->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.isEmpty, true);
		});

		test("Match test - test 2", () {
			Tag tag = go(
				zml: """
					<Container>
					</Container>
				""",

				zss: """
					<ZSS>
						<!--
						A comment.
						-->
						<RULE SEL="Container">
							<p1->hello</p1->
							<p2->world</p2->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Container");
			expect(tag.mapZssToParams.length, 2);
			expect(tag.mapZssToParams.containsKey("p1"), true);
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules.length, 1);
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[0].styleRootTag.uid, 1);
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[0].styleRootTag.tag.name, "p1");
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[0].arrApplicableSelectorParts.length, 0);

			expect(tag.mapZssToParams.containsKey("p2"), true);
			expect(tag.mapZssToParams["p2"]!.arrApplicableRules.length, 1);
			expect(tag.mapZssToParams["p2"]!.arrApplicableRules[0].styleRootTag.uid, 2);
			expect(tag.mapZssToParams["p2"]!.arrApplicableRules[0].styleRootTag.tag.name, "p2");
			expect(tag.mapZssToParams["p2"]!.arrApplicableRules[0].arrApplicableSelectorParts.length, 0);
		});

		test("Match test - tag", () {
			Tag tag = go(
				zml: """
					<Column>
					</Column>
				""",

				zss: """
					<ZSS>
						<!-- simple -->
						<RULE SEL="Column">
							<p1->hello</p1->
						</RULE>
						
						<!-- merge -->
						<RULE SEL="Column">
							<p2->nihao</p2->
							<p3->shalom</p3->
						</RULE>
						
						<!-- override (by order) -->
						<RULE SEL="Column">
							<p3->hi</p3->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 3);
			testParam(tag, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0);
			testParam(tag, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0);
			testParam(tag, "p3", ruleIdx: 0, uid: 4, numSelectorParts: 0);
			expect(tag.mapZssToParams["p3"]!.arrApplicableRules[0].styleRootTag.tag.text, "hi");
		});

		test("Match test - tag + classes", () {
			Tag tag = go(
				zml: """
					<Column class="class1 class2 class3">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column">
							<p1->P1</p1->
						</RULE>
						
						<RULE SEL="Column.class1">
							<p2->P2</p2->
						</RULE>
						
						<RULE SEL="Column.class2">
							<p3->P3</p3->
						</RULE>
						
						<RULE SEL="Column.class3">
							<p4->P4</p4->
						</RULE>
						
						<RULE SEL="Column.class4">
							<p5->P5</p5->
						</RULE>
						
						<RULE SEL="Column.class1.class2">
							<p6->P6</p6->
						</RULE>
						
						<RULE SEL="Column.class1.class3">
							<p7->P7</p7->
						</RULE>
						
						<RULE SEL="Column.class1.class4">
							<p8->P8</p8->
						</RULE>
						
						<RULE SEL="Column.class2.class3">
							<p9->P9</p9->
						</RULE>
						
						<RULE SEL="Column.class2.class3.class4">
							<p10->P10</p10->
						</RULE>
						
						<RULE SEL="Column.class1.class2.class3">
							<p11->P11</p11->
						</RULE>
						
						<RULE SEL="Column.class1.class2.class3.class4">
							<p12->P12</p12->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 8);
			testParam(tag, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0);
			testParam(tag, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0);
			testParam(tag, "p3", ruleIdx: 0, uid: 3, numSelectorParts: 0);
			testParam(tag, "p4", ruleIdx: 0, uid: 4, numSelectorParts: 0);
			testParam(tag, "p6", ruleIdx: 0, uid: 6, numSelectorParts: 0);
			testParam(tag, "p7", ruleIdx: 0, uid: 7, numSelectorParts: 0);
			testParam(tag, "p9", ruleIdx: 0, uid: 9, numSelectorParts: 0);
			testParam(tag, "p11", ruleIdx: 0, uid: 11, numSelectorParts: 0);
		});

		test("Match test - just classes", () {
			Tag tag = go(
				zml: """
					<Column class="class1 class2 class3">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="SomeOtherTag">
							<p1->P1</p1->
						</RULE>
						
						<RULE SEL="Column.class1">
							<p2->P2</p2->
						</RULE>
						
						<RULE SEL="Column.class2">
							<p3->P3</p3->
						</RULE>
						
						<RULE SEL="Column.class3">
							<p4->P4</p4->
						</RULE>
						
						<RULE SEL="Column.class4">
							<p5->P5</p5->
						</RULE>
						
						<RULE SEL="Column.class1.class2">
							<p6->P6</p6->
						</RULE>
						
						<RULE SEL="Column.class1.class3">
							<p7->P7</p7->
						</RULE>
						
						<RULE SEL="Column.class1.class4">
							<p8->P8</p8->
						</RULE>
						
						<RULE SEL="Column.class2.class3">
							<p9->P9</p9->
						</RULE>
						
						<RULE SEL="Column.class2.class3.class4">
							<p10->P10</p10->
						</RULE>
						
						<RULE SEL="Column.class1.class2.class3">
							<p11->P11</p11->
						</RULE>
						
						<RULE SEL="Column.class1.class2.class3.class4">
							<p12->P12</p12->
						</RULE>
					</ZSS>
				""",

				printErrors: true,
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 7);
			testParam(tag, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0);
			testParam(tag, "p3", ruleIdx: 0, uid: 3, numSelectorParts: 0);
			testParam(tag, "p4", ruleIdx: 0, uid: 4, numSelectorParts: 0);
			testParam(tag, "p6", ruleIdx: 0, uid: 6, numSelectorParts: 0);
			testParam(tag, "p7", ruleIdx: 0, uid: 7, numSelectorParts: 0);
			testParam(tag, "p9", ruleIdx: 0, uid: 9, numSelectorParts: 0);
			testParam(tag, "p11", ruleIdx: 0, uid: 11, numSelectorParts: 0);
		});

		test("Match test - override by specificity", () {
			Tag tag = go(
				zml: """
					<Column class="class1 class2 class3">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column.class1.class2">
							<p1->P1-A</p1->
						</RULE>
						
						<RULE SEL="Column.class1.class2.class3">
							<p1->P1-B</p1->
						</RULE>
						
						<RULE SEL="Column.class1">
							<p1->P1-C</p1->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 1);
			testParam(tag, "p1", ruleIdx: 0, uid: 2, numSelectorParts: 0); // P1-B
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[0].styleRootTag.tag.text, "P1-B");
		});

		test("Match test - only dynamic classes", () {
			Tag tag = go(
				zml: """
					<Column z-attr:class="myClasses">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column.class1">
							<p1->P1-A</p1->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 1);
			testParam(tag, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 1); // P1-A
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[0].styleRootTag.tag.text, "P1-A");
		});

		test("Match test - dynamic classes", () {
			Tag tag = go(
				zml: """
					<Column class="class1 classA classB" z-attr:class="moreClasses">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column.class1">
							<p1->P1-A</p1->
						</RULE>

						<RULE SEL="Column.class1.class2">
							<p1->P1-B</p1->
						</RULE>

						<RULE SEL="Column.class1.classA.classB">
							<p1->P1-C</p1->
						</RULE>

						<RULE SEL="Column.class1.class2.class3.class4">
							<p1->P1-D</p1->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 1);
			testParam(tag, "p1", ruleIdx: 0, uid: 3, numSelectorParts: 0); // P1-C
			testParam(tag, "p1", ruleIdx: 1, uid: 4, numSelectorParts: 1); // P1-D

			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[0].styleRootTag.tag.text, "P1-C");
			expect(tag.mapZssToParams["p1"]!.arrApplicableRules[1].styleRootTag.tag.text, "P1-D");
		});

		test("Match test - multiple tags", () {
			Tag tag = go(
				zml: """
					<Column class="class1">
						<Container class="class2"></Container>
						<Container />
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text.class1"> <!-- 101 (5) -->
							<p1->P1-A</p1-> <!-- uid = 1 -->
						</RULE>

						<RULE SEL="Column Text"> <!-- 2 (3) -->
							<p1->P1-B</p1-> <!-- uid = 2 -->
						</RULE>

						<RULE SEL="Column Container.class2"> <!-- 102, container1 (6) -->
							<p1->P1-C</p1-> <!-- uid = 3 -->
						</RULE>

						<RULE SEL="Container"> <!-- 1, container1, container2 (1) -->
							<p1->P1-D</p1-> <!-- uid = 4 -->
							<p2->P2-D</p2-> <!-- uid = 5 -->
						</RULE>
						
						<RULE SEL="Column"> <!-- 1, column (2) -->
							<p3->P3-E</p3-> <!-- uid = 6 -->
						</RULE>
						
						<RULE SEL="Column.class1"> <!-- 101, column (4) -->
							<p4->P4-F</p4-> <!-- uid = 7 -->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapNamedChildren.length, 1);
			expect(tag.mapNamedChildren.containsKey("children"), true);

			expect(tag.mapZssToParams.length, 2);
			testParam(tag, "p3", ruleIdx: 0, uid: 6, numSelectorParts: 0); // P3-E
			testParam(tag, "p4", ruleIdx: 0, uid: 7, numSelectorParts: 0); // P4-F

			List<Tag> arrChildren = tag.mapNamedChildren["children"]!.arrUnnamedChildren;

			expect(arrChildren.length, 2);
			Tag container1 = arrChildren[0];
			Tag container2 = arrChildren[1];
			expect(container1.name, "Container");
			expect(container2.name, "Container");

			expect(container1.mapZssToParams.length, 2);
			testParam(container1, "p1", ruleIdx: 0, uid: 3, numSelectorParts: 0); // P1-C
			testParam(container1, "p2", ruleIdx: 0, uid: 5, numSelectorParts: 0); // P2-D

			expect(container2.mapZssToParams.length, 2);
			testParam(container2, "p1", ruleIdx: 0, uid: 4, numSelectorParts: 0); // P1-D
			testParam(container2, "p2", ruleIdx: 0, uid: 5, numSelectorParts: 0); // P2-D
		});

		test("Match test - multiple tags with skip", () {
			Tag tag = go(
				zml: """
					<Column>
						<Container>
							<Text></Text>
						</Container>
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column Text">
							<p1->P1</p1->
						</RULE>
						<RULE SEL="Column Column Text">
							<p2->P2</p2->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapNamedChildren.length, 1);
			expect(tag.mapNamedChildren.containsKey("children"), true);

			List<Tag> arrColumnChildren = tag.mapNamedChildren["children"]!.arrUnnamedChildren;
			expect(arrColumnChildren.length, 1);

			Tag container = arrColumnChildren[0];
			expect(container.name, "Container");
			expect(container.mapNamedChildren.length, 1);
			expect(container.mapNamedChildren.containsKey("child"), true);

			List<Tag> arrContainerChildren = container.mapNamedChildren["child"]!.arrUnnamedChildren;
			expect(arrContainerChildren.length, 1);

			Tag text = arrContainerChildren[0];
			expect(text.name, "Text");

			expect(text.mapZssToParams.length, 1);
			testParam(text, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0); // P1
		});

		test("Match test - multiple tags with named parameter", () {
			Tag tag = go(
				zml: """
					<Column>
						<namedParam->
							<Container class="class1"></Container>
							<Text class="class1"></Text>
						</namedParam->
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column Container">
							<p1->P1</p1->
						</RULE>
						<RULE SEL="namedParam- Container">
							<p2->P2</p2->
						</RULE>
						<RULE SEL="Column namedParam- Container">
							<p3->P3</p3->
						</RULE>
						<RULE SEL="namedParam- Text.class1">
							<p4->P4</p4->
						</RULE>
						<RULE SEL="Text.class1">
							<p5->P5</p5->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapNamedChildren.length, 1);
			expect(tag.mapNamedChildren.containsKey("namedParam"), true);

			List<Tag> arrColumnChildren = tag.mapNamedChildren["namedParam"]!.arrUnnamedChildren;
			expect(arrColumnChildren.length, 2);


			Tag container = arrColumnChildren[0];
			expect(container.name, "Container");
			expect(container.mapZssToParams.length, 3);
			testParam(container, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0); // P1
			testParam(container, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0); // P2
			testParam(container, "p3", ruleIdx: 0, uid: 3, numSelectorParts: 0); // P3


			Tag text = arrColumnChildren[1];
			expect(text.name, "Text");
			expect(text.mapZssToParams.length, 2);
			testParam(text, "p4", ruleIdx: 0, uid: 4, numSelectorParts: 0); // P4
			testParam(text, "p5", ruleIdx: 0, uid: 5, numSelectorParts: 0); // P5
		});

		test("Match test - multiple tags with positional parameter", () {
			Tag tag = go(
				zml: """
					<Column>
						<:0->
							<Container class="class1"></Container>
							<Text class="class1"></Text>
						</:0->
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column Container">
							<p1->P1</p1->
						</RULE>
						<RULE SEL="0- Container">
							<p2->P2</p2->
						</RULE>
						<RULE SEL="Column 0- Container">
							<p3->P3</p3->
						</RULE>
						<RULE SEL="0- Text.class1">
							<p4->P4</p4->
						</RULE>
						<RULE SEL="Text.class1">
							<p5->P5</p5->
						</RULE>
					</ZSS>
				""", printErrors: true
			);

			expect(tag.name, "Column");
			expect(tag.mapNamedChildren.length, 1);
			expect(tag.mapNamedChildren.containsKey(":0"), true);

			List<Tag> arrColumnChildren = tag.mapNamedChildren[":0"]!.arrUnnamedChildren;
			expect(arrColumnChildren.length, 2);


			Tag container = arrColumnChildren[0];
			expect(container.name, "Container");
			expect(container.mapZssToParams.length, 3);
			testParam(container, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0); // P1
			testParam(container, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0); // P2
			testParam(container, "p3", ruleIdx: 0, uid: 3, numSelectorParts: 0); // P3


			Tag text = arrColumnChildren[1];
			expect(text.name, "Text");
			expect(text.mapZssToParams.length, 2);
			testParam(text, "p4", ruleIdx: 0, uid: 4, numSelectorParts: 0); // P4
			testParam(text, "p5", ruleIdx: 0, uid: 5, numSelectorParts: 0); // P5
		});

		test("Match test - attributes (unquoted)", () {
			Tag tag = go(
				zml: """
					<Column hardcoded="hardcodedAttribute" z-attr:runtime="runtimeAttribute">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column"> <!-- yes -->
							<p1->P1</p1->
						</RULE>
						<RULE SEL="Column[hardcoded]"> <!-- yes -->
							<p2->P2</p2->
						</RULE>
						<RULE SEL="Column[hardcoded=hardcodedAttribute]"> <!-- yes -->
							<p3->P3</p3->
						</RULE>
						<RULE SEL="Column[hardcoded=wrong]"> <!-- yes (dyn) -->
							<p4->P4</p4->
						</RULE>
						<RULE SEL="Column[hardcoded=wrong][runtime]"> <!-- yes (dyn) -->
							<p5->P5</p5->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime]"> <!-- yes -->
							<p6->P6</p6->
						</RULE>
						<RULE SEL="Column[runtime]"> <!-- yes -->
							<p7->P7</p7->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime=runtimeAttribute]"> <!-- yes (dyn) -->
							<p8->P8</p8->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime=another]"> <!-- yes (dyn) -->
							<p9->P9</p9->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime=another][nonexistent]"> <!-- no -->
							<p10->P10</p10->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime=another][nonexistent=nonexistent]"> <!-- no -->
							<p11->P11</p11->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 9);
			testParam(tag, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0); // P1
			testParam(tag, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0); // P2
			testParam(tag, "p3", ruleIdx: 0, uid: 3, numSelectorParts: 0); // P3
			testParam(tag, "p6", ruleIdx: 0, uid: 6, numSelectorParts: 0); // P6
			testParam(tag, "p7", ruleIdx: 0, uid: 7, numSelectorParts: 0); // P7
			testParam(tag, "p8", ruleIdx: 0, uid: 8, numSelectorParts: 1); // P8
			testParam(tag, "p9", ruleIdx: 0, uid: 9, numSelectorParts: 1); // P9

			expect(tag.mapZssToParams["p8"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions != null, true);
			expect(tag.mapZssToParams["p8"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!.containsKey("runtime"), true);
			expect(tag.mapZssToParams["p8"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!["runtime"]!.value, "runtimeAttribute");

			expect(tag.mapZssToParams["p9"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions != null, true);
			expect(tag.mapZssToParams["p9"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!.containsKey("runtime"), true);
			expect(tag.mapZssToParams["p9"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!["runtime"]!.value, "another");
		});

		test("Match test - attributes (quoted)", () {
			Tag tag = go(
				zml: """
					<Column hardcoded="hardcodedAttribute" z-attr:runtime="runtimeAttribute">
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column"> <!-- yes -->
							<p1->P1</p1->
						</RULE>
						<RULE SEL="Column[hardcoded]"> <!-- yes -->
							<p2->P2</p2->
						</RULE>
						<RULE SEL="Column[hardcoded='hardcodedAttribute']"> <!-- yes -->
							<p3->P3</p3->
						</RULE>
						<RULE SEL="Column[hardcoded='wrong']"> <!-- no -->
							<p4->P4</p4->
						</RULE>
						<RULE SEL="Column[hardcoded='wrong'][runtime]"> <!-- no -->
							<p5->P5</p5->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime]"> <!-- yes -->
							<p6->P6</p6->
						</RULE>
						<RULE SEL="Column[runtime]"> <!-- yes -->
							<p7->P7</p7->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime='runtimeAttribute']"> <!-- yes (dyn) -->
							<p8->P8</p8->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime='another']"> <!-- yes (dyn) -->
							<p9->P9</p9->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime='another'][nonexistent]"> <!-- no -->
							<p10->P10</p10->
						</RULE>
						<RULE SEL="Column[hardcoded][runtime='another'][nonexistent='nonexistent']"> <!-- no -->
							<p11->P11</p11->
						</RULE>
					</ZSS>
				"""
			);

			expect(tag.name, "Column");
			expect(tag.mapZssToParams.length, 7);
			testParam(tag, "p1", ruleIdx: 0, uid: 1, numSelectorParts: 0); // P1
			testParam(tag, "p2", ruleIdx: 0, uid: 2, numSelectorParts: 0); // P2
			testParam(tag, "p3", ruleIdx: 0, uid: 3, numSelectorParts: 0); // P3
			testParam(tag, "p6", ruleIdx: 0, uid: 6, numSelectorParts: 0); // P6
			testParam(tag, "p7", ruleIdx: 0, uid: 7, numSelectorParts: 0); // P7
			testParam(tag, "p8", ruleIdx: 0, uid: 8, numSelectorParts: 1); // P8
			testParam(tag, "p9", ruleIdx: 0, uid: 9, numSelectorParts: 1); // P9

			expect(tag.mapZssToParams["p8"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions != null, true);
			expect(tag.mapZssToParams["p8"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!.containsKey("runtime"), true);
			expect(tag.mapZssToParams["p8"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!["runtime"]!.value, "'runtimeAttribute'");

			expect(tag.mapZssToParams["p9"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions != null, true);
			expect(tag.mapZssToParams["p9"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!.containsKey("runtime"), true);
			expect(tag.mapZssToParams["p9"]!.arrApplicableRules[0].arrApplicableSelectorParts[0].selectorPart.mapAttrConditions!["runtime"]!.value, "'another'");
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

Tag go({ required String zml, required String zss, bool printErrors = false }) {
	SvcLogger svcLogger = SvcLogger.i();
	SvcZmlParser svcZmlParser = SvcZmlParser.i();
	SvcZssParser svcZssParser = SvcZssParser.i();
	SvcZssMatcher svcZssMatcher = SvcZssMatcher.i();
	StylingTag.resetNextUidForTesting();

	Tag? transTag;
	ZssRuleSet? maybeZssRuleSet;
	svcLogger.invoke(() {
		Tag? maybeTag = svcZmlParser.tryParse(zml);
		expect(maybeTag != null, true);

		transTag = svcZmlTransformer.transform(maybeTag!);

		maybeZssRuleSet = svcZssParser.parse(zss, transTag!);
		expect(maybeZssRuleSet != null, true);
	});
	if (printErrors && svcLogger.hasLoggedErrors()) {
		svcLogger.printLoggedErrorsIfNeeded();
	}

	svcZssMatcher.matchZssToTags(transTag!, maybeZssRuleSet!);

	return transTag!;
}