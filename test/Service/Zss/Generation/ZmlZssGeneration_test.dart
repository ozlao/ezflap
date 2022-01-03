
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';
import '../../Zml/Generator/Utils/ZmlGeneratorTestUtils.dart';

SvcLogger svcLogger = SvcLogger.i();

AstNodeWrapper _verifyDart({ required String zml, required String dart, required String zss, required bool getBuilderZssStyleFunctionsInstead }) {
	return ZmlGeneratorTestUtils.verifyDart(zml: zml, zss: zss, dart: dart, getBuilderZssStyleFunctionsInstead: getBuilderZssStyleFunctionsInstead);
}

void main() async {
	await ReflectorBootstrapper.initReflectorForTesting();

	group("Testing ZmlZssCompilation", () {
		test("ZmlZssCompilation test - styles generation", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Text>
						hello world
					</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text">
							<textAlign->TextAlign.left</textAlign->
							<textDirection->TextDirection.ltr</textDirection->
							<locale->
								<Locale>
									<:0->"en"</:0->
								</Locale>
							</locale->
						</RULE>
					</ZSS>
				""",

				dart: """
					Locale? _zssStyle_3() => (Locale("en",));
					TextAlign? _zssStyle_1() => TextAlign.left;
					TextDirection? _zssStyle_2() => TextDirection.ltr;
				""",

				getBuilderZssStyleFunctionsInstead: true,
			);

			expect(wrapper.rootConstructorNode.name, "Text");
			expect(wrapper.mapZssStyleNodes.length, 3);
			expect(wrapper.mapZssStyleNodes.containsKey(1), true);
			expect(wrapper.mapZssStyleNodes.containsKey(2), true);
			expect(wrapper.mapZssStyleNodes.containsKey(3), true);
		});

		test("ZmlZssCompilation test - builder generation", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Text>
						hello world
					</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text">
							<textAlign->TextAlign.left</textAlign->
							<textDirection->TextDirection.ltr</textDirection->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Text(\"""hello world\""",
						textAlign: _zssStyle_1(),
						textDirection: _zssStyle_2()
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);

			expect(wrapper.rootConstructorNode.name, "Text");
			expect(wrapper.mapZssStyleNodes.length, 2);
		});

		test("ZmlZssCompilation test - builder generation - classes", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Text z-attr:class="myClasses">hello world</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text.class1">
							<textAlign->TextAlign.left</textAlign->
							<textDirection->TextDirection.ltr</textDirection->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Text(\"""hello world\""",
						textAlign: (myClasses.containsAll({ "class1" })) ? _zssStyle_1() : null,
						textDirection: (myClasses.containsAll({ "class1" })) ? _zssStyle_2() : null
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);
		});

		test("ZmlZssCompilation test - builder generation - classes in cascade", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Container z-attr:class="containerClasses">
						<Text z-attr:class="textClasses">hello world</Text>
					</Container>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Container.classOfContainer Text.classOfText">
							<textAlign->TextAlign.left</textAlign->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Container(
						child: (Text(
							\"""hello world\""",
							textAlign: (textClasses.containsAll({ "classOfText" })) && (containerClasses.containsAll({ "classOfContainer" })) ? _zssStyle_1() : null
						))
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);
		});

		test("ZmlZssCompilation test - builder generation - multiple rules with classes", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Container z-attr:class="containerClasses">
						<Text z-attr:class="textClasses">hello world</Text>
					</Container>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text.classOfText2">
							<textAlign->TextAlign.right</textAlign->
						</RULE>
						<RULE SEL="Container.classOfContainer Text.classOfText">
							<textAlign->TextAlign.left</textAlign->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Container(
						child: (Text(
							\"""hello world\""",
							textAlign:
								(textClasses.containsAll({ "classOfText" })) && (containerClasses.containsAll({ "classOfContainer" })) ? _zssStyle_2()
									: (textClasses.containsAll({ "classOfText2" })) ? _zssStyle_1()
										: null
						))
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);
		});

		test("ZmlZssCompilation test - builder generation - attrs (unquoted)", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Text z-attr:status="myStatus" z-attr:id="myId">hello world</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text[status=new][id=100]">
							<textAlign->TextAlign.left</textAlign->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Text(\"""hello world\""",
						textAlign: ((EzStateBase.\$testAttr(new, myStatus) && EzStateBase.\$testAttr(100, myId))) ? _zssStyle_1() : null
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);
		});

		test("ZmlZssCompilation test - builder generation - attrs (quoted)", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Text z-attr:status="myStatus" z-attr:id="myId">hello world</Text>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Text[status='new'][id='100']">
							<textAlign->TextAlign.left</textAlign->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Text(\"""hello world\""",
						textAlign: ((EzStateBase.\$testAttr('new', myStatus) && EzStateBase.\$testAttr('100', myId))) ? _zssStyle_1() : null
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);
		});

		test("ZmlZssCompilation test - misc 1", () {
			AstNodeWrapper wrapper = _verifyDart(
				zml: """
					<Column z-attr:seconds="seconds" z-attr:class="myClasses">
						<Text class="class1">Text 1</Text>
						<Text z-if="seconds == 42">In Sub! Hello: {{ hello }}</Text>
					</Column>
				""",

				zss: """
					<ZSS>
						<RULE SEL="Column[seconds=10] Text.class1">
							<textAlign->TextAlign.left</textAlign->
						</RULE>
						<RULE SEL="Column[seconds=20] Text.class1">
							<textAlign->TextAlign.right</textAlign->
						</RULE>
						<RULE SEL="Column.class2 Text.class1">
							<textAlign->TextAlign.end</textAlign->
						</RULE>
					</ZSS>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""Text 1\""",
								textAlign: ((EzStateBase.\$testAttr(10, seconds))) ? _zssStyle_1()
									: ((EzStateBase.\$testAttr(20, seconds))) ? _zssStyle_2()
										: (myClasses.containsAll({ "class2" })) ? _zssStyle_3()
											: null
							)),
							if (seconds == 42)
								(Text(\"""In Sub! Hello: \${ hello }\""",))
						]
					));
				""",

				getBuilderZssStyleFunctionsInstead: false,
			);
		});
	});
}
