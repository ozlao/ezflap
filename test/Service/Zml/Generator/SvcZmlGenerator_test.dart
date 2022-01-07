
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Utils/EzUtils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';
import 'Utils/ZmlGeneratorTestUtils.dart';

SvcLogger svcLogger = SvcLogger.i();

void _verifyDart({ required String zml, required String dart }) {
	ZmlGeneratorTestUtils.verifyDart(zml: zml, dart: dart);
}

void main() async {
	String dir = EzUtils.getDirFromUri(EzUtils.getCallerUri());
	String customEntryPoint = "${dir}/SvcZmlGenerator_test_CustomEntryPoint.dart";
	await ReflectorBootstrapper.initReflectorForTesting(customEntryPoint);

	group("Testing SvcZmlGenerator", () {
		test("Generator test - backslash text", () {
			_verifyDart(
				zml: """
					<Column>
						<Text>hello \\{{ var1 }} text 2\\</Text>
						<Text>hello \\{{ {{ var1 }} \\text 2</Text>
						<Text>hello \\{{{ var1 }} \\text 2</Text>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""hello {{ var1 }} text 2\\\\\""",)),
							(Text(\"""hello {{ \${ var1 } \\\\text 2\""",)),
							(Text(\"""hello {\${ var1 } \\\\text 2\""",))
						]
					));
				""",
			);
		});

		test("Generator test - various texts", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<Text>{{ var1 }} text 2</Text>
							<Text>hello {{ var1 }} text 3</Text>
							<Text>hello {{ var1 }}{{ var2 }} text 2</Text>
							<Text>hello {{ var1 }} abc {{ var2 }} text 2</Text>
							<Text>hello {{ var1 }} abc {{ var2 }}</Text>
							<Text>hello {{ var1.var2 + (var3 * var4) }} abc {{ var5 }}</Text>
							<Text>hello \\{{ var1 }} text 2\\</Text>
							<Text>hello \\{{ {{ var1 }} \\text 2</Text>
							<Text>hello {{ {{ var1 }} text 2</Text>
							<Text>hello {{ {{ var1 }} }} text 2</Text>
							<Text>hello <!-- {{ --> var1 }} text 2</Text>
						</children->
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text(\"""text 1\""",)),
							(Text(\"""\${ var1 } text 2\""",)),
							(Text(\"""hello \${ var1 } text 3\""",)),
							(Text(\"""hello \${ var1 }\${ var2 } text 2\""",)),
							(Text(\"""hello \${ var1 } abc \${ var2 } text 2\""",)),
							(Text(\"""hello \${ var1 } abc \${ var2 }\""",)),
							(Text(\"""hello \${ var1.var2 + (var3 * var4) } abc \${ var5 }\""",)),
							(Text(\"""hello {{ var1 }} text 2\\\\\""",)),
							(Text(\"""hello {{ \${ var1 } \\\\text 2\""",)),
							(Text(\"""hello \${ {{ var1 } text 2\""",)),
							(Text(\"""hello \${ {{ var1 } }} text 2\""",)),
							(Text(\"""hello var1 }} text 2\""",))
						]
					));
				""",
			);
		});

		test("Generator test - scaffold with body", () {
			_verifyDart(
				zml: """
					<Scaffold>
						<body->
							<Container>
								<child->
									<Text>hello: {{ hello }}, counter: {{ counter }}</Text>
								</child->
							</Container>
						</body->
					</Scaffold>	
				""",

				dart: """
					return (Scaffold(
						body: (Container(
							child: (Text(\"""hello: \${ hello }, counter: \${ counter }\""",))
						))
					));
				""",
			);
		});

		test("Generator test - z-if", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<Text z-if="shouldRenderText2">text 2</Text>
							<Text>text 3</Text>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							if (shouldRenderText2)
								(Text(${t("text 2")})),
							(Text(${t("text 3")}))
						]
					));
				""",
			);
		});

		test("Generator test - z-show", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<Text z-show="shouldShowText2">text 2</Text>
							<Text z-if="shouldRenderText3" z-show="shouldShowText3">text 3</Text>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							(Visibility(
								child: Text(${t("text 2")}),
								maintainState: true,
								visible: shouldShowText2,
							)),
							if (shouldRenderText3)
								(Visibility(
									child: Text(${t("text 3")}),
									maintainState: true,
									visible: shouldShowText3,
								))
						]
					));
				""",
			);
		});

		test("Generator test - z-for", () {
			// syntax 1: "iter in collection"
			// syntax 2: "(key, value) in collection"
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<Text z-for="v in arrTexts">text 2</Text>
							<Text z-for="(v, idx) in arrTexts">text 3</Text>
							<Text z-for="v in arrTexts" z-if="myIf">text 4</Text>
							<Text z-for="v in arrTexts" z-show="myShow">text 5</Text>
							<Text z-for="v in arrTexts" z-if="myIf" z-show="myShow">text 6</Text>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							...\$EzStateBase.\$autoMapper(arrTexts, (v, _\$1, _\$2) => Text(${t("text 2")})),
							...\$EzStateBase.\$autoMapper(arrTexts, (v, idx, _\$2) => Text(${t("text 3")})),
							...\$EzStateBase.\$autoMapper(arrTexts, (v, _\$1, _\$2) => ( 
								(myIf) ? (Text(${t("text 4")})) : null
							)),
							...\$EzStateBase.\$autoMapper(arrTexts, (v, _\$1, _\$2) =>  
								Visibility(
									child: Text(${t("text 5")}),
									maintainState: true,
									visible: myShow,
								)
							),
							...\$EzStateBase.\$autoMapper(arrTexts, (v, _\$1, _\$2) => (
								(myIf) ?
									(
										Visibility(
											child: Text(${t("text 6")}),
											maintainState: true,
											visible: myShow,
										)
									)
									: null
							))
						]
					));
				""",
			);
		});

		test("Generator test - z-bind", () {
			_verifyDart(
				zml: """
					<Column z-bind:hello="world">
						<children->
							<Text>text 1</Text>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")}))
						],
						hello: world
					));
				""",
			);
		});

		test("Generator test - ZGroup", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<ZGroup z-if="groupTest1a || groupTest1b">
								<Text>text 1</Text>
								<Text z-if="shouldRenderText2">text 2</Text>
								<ZGroup>
									<Text>text 3</Text>
								</ZGroup>
								<ZGroup z-if="groupTest2" z-show="groupTestShow2">
								</ZGroup>
								<ZGroup z-if="groupTest3" z-show="groupTestShow3">
									<Text z-show="shouldRenderText4">text 4</Text>
								</ZGroup>
								<Column>
									<children->
										<ZGroup z-if="groupTest4">
											<Text z-if="shouldRenderText5">text 5</Text>
										</ZGroup>
										<ZGroup z-if="groupTest5">
											<ZGroup z-if="groupTest6">
												<Text z-if="shouldRenderText6">text 6</Text>
											</ZGroup>
											<Text z-for="item in arrItems" z-if="shouldInclude(item)">
												text 7
											</Text>
										</ZGroup>
									</children->
								</Column>
							</ZGroup>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							if (((groupTest1a || groupTest1b)))
								(Text(${t("text 1")})),
							if (((groupTest1a || groupTest1b)))
								if (shouldRenderText2)
									(Text(${t("text 2")})),
							if (((groupTest1a || groupTest1b)))
								(Text(${t("text 3")})),
							if (((groupTest1a || groupTest1b) && (groupTest3)))
								(Visibility(
									child: Text(${t("text 4")}),
									maintainState: true,
									visible: ((((groupTestShow3))) && (shouldRenderText4)),
								)),
							if (((groupTest1a || groupTest1b)))
								(Column(
									children: [
										if (((groupTest4)))
											if (shouldRenderText5)
												(Text(${t("text 5")})),
										if (((groupTest5) && (groupTest6)))
											if (shouldRenderText6)
												(Text(${t("text 6")})),
										if (((groupTest5)))
											...\$EzStateBase.\$autoMapper(arrItems, (item, _\$1, _\$2) => (
												(shouldInclude(item)) ? (Text(${t("text 7")})) : null
											))
									]
								))
						]
					));
				""",
			);
		});

		test("Generator test - ZBuild", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<ZBuild z-build="make()" />
							<ZBuild z-builder="builder" />
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							(make()),
							if ((builder as dynamic) != null)
								(builder as dynamic)!(context)
						]
					));
				""",
			);
		});

		test("Generator test - ZBuild ezflap widget", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<ZBuild z-build="make()" />
							<ZBuild z-builder="builder" />
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							(make()),
							if ((builder as dynamic) != null)
								(builder as dynamic)!(context)
						]
					));
				""",
			);
		});

		test("Generator test - ZBuild ezflap widget with z-bind, z-ref, and ZSlotProvider", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<ZBuild z-build="make()"
								z-bind:myBind="42"
								z-ref="myRef"
							>
								<ZSlotProvider z-name="slotProvider">
									<Text>provider1</Text>
								</ZSlotProvider>
							</ZBuild>
							<ZBuild z-builder="builder"
								z-bind:myBind="42"
								z-ref="myRef"
							>
								<ZSlotProvider z-name="slotProvider">
									<Text>provider2</Text>
								</ZSlotProvider>
							</ZBuild>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							(make()
								..\$initProps({ "myBind": 42 })
								..\$initSlotProviders({ "slotProvider": \$SlotProvider(name: "slotProvider", funcBuild: (dynamic _) { return [ (Text(\"\"\"provider1\"\"\",)) ]; }) })
								..\$initLifecycleHandlers((ref) => _ref_myRef.setValue(ref as dynamic), (ref) => _ref_myRef.setValue(null))
							),
							if ((builder as dynamic) != null)
								(builder as dynamic)!(context)
									..\$initProps({ "myBind": 42 })
									..\$initSlotProviders({ "slotProvider": \$SlotProvider(name: "slotProvider", funcBuild: (dynamic _) { return [ (Text(\"\"\"provider2\"\"\",)) ]; }) })
									..\$initLifecycleHandlers((ref) => _ref_myRef.setValue(ref as dynamic), (ref) => _ref_myRef.setValue(null))
						]
					));
				""",
			);
		});

		test("Generator test - ZBuild ezflap widget with interpolated text", () {
			_verifyDart(
				zml: """
					<Column>
						<children->
							<Text>text 1</Text>
							<ZBuild z-build="make()">
								interpolated1
							</ZBuild>
							<ZBuild z-builder="builder">
								interpolated2
							</ZBuild>
						</children->
					</Column>	
				""",

				dart: """
					return (Column(
						children: [
							(Text(${t("text 1")})),
							(make()
								..\$setInterpolatedText(\"\"\"interpolated1\"\"\")
							),
							if ((builder as dynamic) != null)
								(builder as dynamic)!(context)
									..\$setInterpolatedText(\"\"\"interpolated2\"\"\")
						]
					));
				""",
			);
		});

		test("Generator test - provider slot, with explicit default", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestSlotsExtendEzStatefulWidget>
						<ZSlotProvider>
							<Text>provider: anonymous</Text>
						</ZSlotProvider>
						<ZSlotProvider z-name="provider1">
							<Text>provider: one</Text>
						</ZSlotProvider>
						<ZSlotProvider z-name="provider2">
							<Text>provider: two</Text>
						</ZSlotProvider>
						
						<children->
							<ZSlotConsumer>
								<Text>consumer: anonymous</Text>
							</ZSlotConsumer>
							<ZSlotConsumer z-name="consumer1">
								<Text>consumer: one</Text>
							</ZSlotConsumer>
							<ZSlotConsumer z-name="consumer2">
								<Text>consumer: two</Text>
							</ZSlotConsumer>
						</children->
					</ZmlGeneratorTestSlotsExtendEzStatefulWidget>	
				""",

				dart: """
					return (this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestSlotsExtendEzStatefulWidget",
							() => ZmlGeneratorTestSlotsExtendEzStatefulWidget())
						..\$initProps({
							"children": [
								if (!this._ezState.widget.\$hasSlotProvider(null)) ...[
									(Text(
										\"\"\"consumer: anonymous\"\"\",
									))
								],
								if (this._ezState.widget.\$hasSlotProvider(null))
									...(this._ezState.widget.\$getSlotProviderWidgets(null, {})),
								if (!this._ezState.widget.\$hasSlotProvider("consumer1")) ...[
									(Text(
										\"\"\"consumer: one\"\"\",
									))
								],
								if (this._ezState.widget.\$hasSlotProvider("consumer1"))
									...(this._ezState.widget.\$getSlotProviderWidgets("consumer1", {})),
								if (!this._ezState.widget.\$hasSlotProvider("consumer2")) ...[
									(Text(
										\"\"\"consumer: two\"\"\",
									))
								],
								if (this._ezState.widget.\$hasSlotProvider("consumer2"))
									...(this._ezState.widget.\$getSlotProviderWidgets("consumer2", {}))
							]
						})
						..\$initSlotProviders({
							null: \$SlotProvider(
									name: null,
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: anonymous\"\"\",
											))
										];
									}),
							"provider1": \$SlotProvider(
									name: "provider1",
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: one\"\"\",
											))
										];
									}),
							"provider2": \$SlotProvider(
									name: "provider2",
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: two\"\"\",
											))
										];
									})
						}));
				""",
			);
		});

		test("Generator test - provider and consumer slots", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestSlotsExtendEzStatefulWidget>
						<ZSlotProvider z-name="provider1">
							<Text>provider: one</Text>
						</ZSlotProvider>
						<ZSlotProvider z-name="provider2">
							<Text>provider: two</Text>
						</ZSlotProvider>
						
						<children->
							<ZSlotConsumer />
							<ZSlotConsumer>
								<Text>consumer: anonymous</Text>
							</ZSlotConsumer>
							<ZSlotConsumer z-name="consumer1">
								<Text>consumer: one</Text>
							</ZSlotConsumer>
							<ZSlotConsumer z-name="consumer2">
								<Text>consumer: two</Text>
							</ZSlotConsumer>
							<ZSlotConsumer z-name="consumer3" />
						</children->
					</ZmlGeneratorTestSlotsExtendEzStatefulWidget>	
				""",

				dart: """
					return (this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestSlotsExtendEzStatefulWidget",
							() => ZmlGeneratorTestSlotsExtendEzStatefulWidget())
						..\$initProps({
							"children": [
								if (this._ezState.widget.\$hasSlotProvider(null))
									...(this._ezState.widget.\$getSlotProviderWidgets(null, {})),
								if (!this._ezState.widget.\$hasSlotProvider(null)) ...[
									(Text(
										\"\"\"consumer: anonymous\"\"\",
									))
								],
								if (this._ezState.widget.\$hasSlotProvider(null))
									...(this._ezState.widget.\$getSlotProviderWidgets(null, {})),
								if (!this._ezState.widget.\$hasSlotProvider("consumer1")) ...[
									(Text(
										\"\"\"consumer: one\"\"\",
									))
								],
								if (this._ezState.widget.\$hasSlotProvider("consumer1"))
									...(this._ezState.widget.\$getSlotProviderWidgets("consumer1", {})),
								if (!this._ezState.widget.\$hasSlotProvider("consumer2")) ...[
									(Text(
										\"\"\"consumer: two\"\"\",
									))
								],
								if (this._ezState.widget.\$hasSlotProvider("consumer2"))
									...(this._ezState.widget.\$getSlotProviderWidgets("consumer2", {})),
								if (this._ezState.widget.\$hasSlotProvider("consumer3"))
									...(this._ezState.widget.\$getSlotProviderWidgets("consumer3", {}))
							]
						})
						..\$initSlotProviders({
							"provider1": \$SlotProvider(
									name: "provider1",
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: one\"\"\",
											))
										];
									}),
							"provider2": \$SlotProvider(
									name: "provider2",
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: two\"\"\",
											))
										];
									})
						}));
				""",
			);
		});


		test("Generator test - provider slot, with implicit default", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestSlotsNoChildrenExtendEzStatefulWidget>
						<Text>provider: anonymous</Text>
						<ZSlotProvider z-name="provider1">
							<Text>provider: one</Text>
						</ZSlotProvider>
						<ZSlotProvider z-name="provider2">
							<Text>provider: two</Text>
						</ZSlotProvider>
					</ZmlGeneratorTestSlotsNoChildrenExtendEzStatefulWidget>	
				""",

				dart: """
					return (this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestSlotsNoChildrenExtendEzStatefulWidget",
							() => ZmlGeneratorTestSlotsNoChildrenExtendEzStatefulWidget())
						..\$initSlotProviders({
							"provider1": \$SlotProvider(
									name: "provider1",
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: one\"\"\",
											))
										];
									}),
							"provider2": \$SlotProvider(
									name: "provider2",
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: two\"\"\",
											))
										];
									}),
							null: \$SlotProvider(
									name: null,
									funcBuild: (dynamic _) {
										return [
											(Text(
												\"\"\"provider: anonymous\"\"\",
											))
										];
									})
						}));
				""",
			);
		});

		test("Generator test - slot with one child, in list", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget>
						<child->
							<ZSlotConsumer />
						</child->
					</ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget>	
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget", () => ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget())
							..\$initProps({
								"child": this._ezState.widget.\$getSlotProviderWidgets(null, { }).first
							})
					);
				""",
			);
		});

		test("Generator test - custom constructor name", () {
			_verifyDart(
				zml: """
					<Column>
						<Text z-constructor="rich">
							<:0->
								<TextSpan>
									<text->
										"hello world"
									</text->
								</TextSpan>
							</:0->
						</Text>
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Text.rich(
								(TextSpan(
									text: "hello world"
								)),
							))
						]
					));
				""",
			);
		});

		test("Generator test - zKey on ezflap widget", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget z-key="helloWorld" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget", () => ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget())
							..\$initProps({
								"key": Key("helloWorld")
							})
					);
				""",
			);
		});

		test("Generator test - interpolated text on ezflap widget", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget>
						hello {{ 21 * 2 }} world
					</ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget>
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget", () => ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget())
							..\$setInterpolatedText(\"\"\"hello \${ 21 * 2 } world\"\"\")
					);
				""",
			);
		});

		test("Generator test - mutually-exclusive children in a single-child parameter - one child", () {
			_verifyDart(
				zml: """
					<Container>
						<Column z-if="test1" />
					</Container>
				""",

				dart: """
					return (Container(
						child: (test1) ? (Column()) : null
					));
				""",
			);
		});

		test("Generator test - mutually-exclusive children in a single-child parameter - three children", () {
			_verifyDart(
				zml: """
					<Container>
						<Column z-if="test1" />
						<Column z-if="test2" />
						<Column z-if="test3" />
					</Container>
				""",

				dart: """
					return (Container(
						child: (test1) ? (Column()) : (test2) ? (Column()) : (test3) ? (Column()) : null
					));
				""",
			);
		});

		test("Generator test - mutually-exclusive child ezFlap widgets", () {
			_verifyDart(
				zml: """
					<Container>
						<ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget z-if="cond == 1" />
						<ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget z-if="cond == 2" />
						<ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget z-if="cond == 3" />
					</Container>
				""",

				dart: """
					return (Container(
						child:
							(cond == 1) ? (this._ezState.\$instantiateOrMock("ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget", () => ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget()))
								 : (cond == 2) ? (this._ezState.\$instantiateOrMock("ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget", () => ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget()))
									 : (cond == 3) ? (this._ezState.\$instantiateOrMock("ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget", () => ZmlGeneratorTestSlotsSingleChildExtendEzStatefulWidget()))
								        : null
					));
				""",
			);
		});

		test("Generator test - mutually-exclusive child ezFlap widgets with props", () {
			_verifyDart(
				zml: """
					<Container>
						<ZmlGeneratorTestPet z-bind:pet="Dog" z-if="cond == 1" />
						<ZmlGeneratorTestPet z-bind:pet="Cat" z-if="cond == 2" />
						<ZmlGeneratorTestPet z-bind:pet="Sloth" z-if="cond == 3" />
					</Container>
				""",

				dart: """
					return (
						Container(
							child:
								(cond == 1) ?
									(this._ezState.\$instantiateOrMock("ZmlGeneratorTestPet", () => ZmlGeneratorTestPet())
										..initProp<String>("pet", Dog)
									)
									:
									(cond == 2) ? 
										(this._ezState.\$instantiateOrMock("ZmlGeneratorTestPet", () => ZmlGeneratorTestPet())
											..initProp<String>("pet", Cat)
										)
										:
										(cond == 3) ? 
											(this._ezState.\$instantiateOrMock("ZmlGeneratorTestPet", () => ZmlGeneratorTestPet())
												..initProp<String>("pet", Sloth)
											)
											: null
						)
					);
				""",
			);
		});

		test("Generator test - mutually-exclusive child ezFlap widgets with string props", () {
			_verifyDart(
				zml: """
					<Container>
						<ZmlGeneratorTestPet pet="Dog" z-if="cond == 1" />
						<ZmlGeneratorTestPet pet="Cat" z-if="cond == 2" />
						<ZmlGeneratorTestPet pet="Sloth" z-if="cond == 3" />
					</Container>
				""",

				dart: """
					return (
						Container(
							child:
								(cond == 1) ?
									(this._ezState.\$instantiateOrMock("ZmlGeneratorTestPet", () => ZmlGeneratorTestPet())
										..\$initProps({ "pet": \"\"\"Dog\"\"\" })
									)
									:
									(cond == 2) ? 
										(this._ezState.\$instantiateOrMock("ZmlGeneratorTestPet", () => ZmlGeneratorTestPet())
											..\$initProps({ "pet": \"\"\"Cat\"\"\" })
										)
										:
										(cond == 3) ? 
											(this._ezState.\$instantiateOrMock("ZmlGeneratorTestPet", () => ZmlGeneratorTestPet())
												..\$initProps({ "pet": \"\"\"Sloth\"\"\" })
											)
											: null
						)
					);
				""",
			);
		});

		test("Generator test - native, no-key", () {
			_verifyDart(
				zml: """
					<Column>
						<Container />
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Container())
						]
					));
				""",
			);
		});

		test("Generator test - native, z-key", () {
			_verifyDart(
				zml: """
					<Column>
						<Container z-key="helloWorld" />
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Container(
								key: Key("helloWorld")
							))
						]
					));
				""",
			);
		});

		test("Generator test - native, z-bind:key", () {
			_verifyDart(
				zml: """
					<Column>
						<Container z-bind:key="Key('nihaoShijie')" />
					</Column>
				""",

				dart: """
					return (Column(
						children: [
							(Container(
								key: Key('nihaoShijie')
							))
						]
					));
				""",
			);
		});

		test("Generator test - ezflap, no key in constructor or prop, no key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestNoKeyInConstructorOrProp />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestNoKeyInConstructorOrProp", () => ZmlGeneratorTestNoKeyInConstructorOrProp())
					);
				""",
			);
		});

		test("Generator test - ezflap, no key in constructor or prop, z-key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestNoKeyInConstructorOrProp z-key="helloWorld" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestNoKeyInConstructorOrProp", () => ZmlGeneratorTestNoKeyInConstructorOrProp())
							..\$initProps({
								"key": Key("helloWorld")
							})
					);
				""",
			);
		});

		test("Generator test - ezflap, no key in constructor or prop, z-bind:key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestNoKeyInConstructorOrProp z-bind:key="Key('nihaoShijie')" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestNoKeyInConstructorOrProp",
							() => ZmlGeneratorTestNoKeyInConstructorOrProp()
						)
						..\$initProps({ "key": Key('nihaoShijie') })
					);
				""",
			);
		});

		test("Generator test - ezflap, no key in constructor but key in prop, no key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestNoKeyInConstructorButKeyInProp />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestNoKeyInConstructorButKeyInProp", () => ZmlGeneratorTestNoKeyInConstructorButKeyInProp())
					);
				""",
			);
		});

		test("Generator test - ezflap, no key in constructor but key in prop, z-key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestNoKeyInConstructorButKeyInProp z-key="helloWorld" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestNoKeyInConstructorButKeyInProp", () => ZmlGeneratorTestNoKeyInConstructorButKeyInProp())
							..\$initProps({
								"key": Key("helloWorld")
							})
					);
				""",
			);
		});

		test("Generator test - ezflap, no key in constructor but key in prop, z-bind:key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestNoKeyInConstructorButKeyInProp z-bind:key="Key('nihaoShijie')" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestNoKeyInConstructorButKeyInProp",
							() => ZmlGeneratorTestNoKeyInConstructorButKeyInProp()
						)
						..initProp<Key>("key", Key('nihaoShijie'))
					);
				""",
			);
		});

		test("Generator test - ezflap, key in constructor but not in prop, no key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestKeyInConstructorButNotInProp />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestKeyInConstructorButNotInProp", () => ZmlGeneratorTestKeyInConstructorButNotInProp())
					);
				""",
			);
		});

		test("Generator test - ezflap, key in constructor but not in prop, z-key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestKeyInConstructorButNotInProp z-key="helloWorld" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestKeyInConstructorButNotInProp",
							() => ZmlGeneratorTestKeyInConstructorButNotInProp(key: Key("helloWorld"))
						)
						..\$initProps({
							"key": Key("helloWorld")
						})
					);
				""",
			);
		});

		test("Generator test - ezflap, key in constructor but not in prop, z-bind:key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestKeyInConstructorButNotInProp z-bind:key="Key('nihaoShijie')" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestKeyInConstructorButNotInProp",
							() => ZmlGeneratorTestKeyInConstructorButNotInProp(key: Key('nihaoShijie'))
						)
						..initProp<Key>("key", Key('nihaoShijie'))
					);
				""",
			);
		});

		test("Generator test - ezflap, key in constructor and in prop, no key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestKeyInConstructorAndInProp />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock("ZmlGeneratorTestKeyInConstructorAndInProp", () => ZmlGeneratorTestKeyInConstructorAndInProp())
					);
				""",
			);
		});

		test("Generator test - ezflap, key in constructor and in prop, z-key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestKeyInConstructorAndInProp z-key="helloWorld" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestKeyInConstructorAndInProp",
							() => ZmlGeneratorTestKeyInConstructorAndInProp(key: Key("helloWorld"))
						)
						..\$initProps({
							"key": Key("helloWorld")
						})
					);
				""",
			);
		});

		test("Generator test - ezflap, key in constructor and in prop, z-bind:key", () {
			_verifyDart(
				zml: """
					<ZmlGeneratorTestKeyInConstructorAndInProp z-bind:key="Key('nihaoShijie')" />
				""",

				dart: """
					return (
						this._ezState.\$instantiateOrMock(
							"ZmlGeneratorTestKeyInConstructorAndInProp",
							() => ZmlGeneratorTestKeyInConstructorAndInProp(key: Key('nihaoShijie'))
						)
						..initProp<Key>("key", Key('nihaoShijie'))
					);
				""",
			);
		});
	});
}