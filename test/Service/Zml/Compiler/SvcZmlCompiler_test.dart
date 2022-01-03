
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/AST/AstNodes.dart';
import 'package:ezflap/src/Service/Zml/Compiler/SvcZmlCompiler_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:ezflap/src/Utils/EzError/EzError.dart';
import 'package:ezflap/src/Utils/EzUtils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';

Future<void> main() async {
	String dir = EzUtils.getDirFromUri(EzUtils.getCallerUri());
	String customEntryPoint = "${dir}/SvcZmlCompiler_test_CustomEntryPoint.dart";
	await ReflectorBootstrapper.initReflectorForTesting(customEntryPoint);

	group("Testing SvcZmlCompiler", () {
		SvcLogger svcLogger = SvcLogger.i();
		SvcZmlCompiler svcZmlCompiler = SvcZmlCompiler.i();
		SvcZmlTransformer svcZmlTransformer = SvcZmlTransformer.i();
		SvcZmlParser svcZmlParser = SvcZmlParser.i();

		svcZmlTransformer.bootstrapDefaultTransformers();

		test("AST test 1", withLogger(() {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Container>
					<child->
						<Text>
							<:0->
								hello world
							</:0->
						</Text>
					</child->
				</Container>
			""");

			expect(maybeTag != null, true);
			Tag tag = svcZmlTransformer.transform(maybeTag!);
			// Tag tag = maybeTag!;

			AstNodeBase? maybeNode = svcZmlCompiler.tryGenerateAst(tag);
			expect(maybeNode != null, true);

			AstNodeBase nodeBase = maybeNode!;
			expect(nodeBase is AstNodeWrapper, true);
			AstNodeWrapper nodeWrapper = nodeBase as AstNodeWrapper;

			AstNodeConstructor node = nodeWrapper.rootConstructorNode;
			expect(node.name, "Container");
			expect(node.isEzflapWidget, false);
			expect(node.arrPositionalParams, [ ]);
			expect(node.mapNamedParams.length, 1);
			expect(node.mapNamedParams.containsKey("child"), true);

			AstNodeBase? textNodeBase = node.mapNamedParams["child"];
			expect(textNodeBase != null, true);
			expect(textNodeBase is AstNodeZssParameterValue, true);
			expect((textNodeBase as AstNodeZssParameterValue).valueNode is AstNodeConstructor, true);

			AstNodeConstructor textNode = textNodeBase.valueNode as AstNodeConstructor;
			expect(textNode.name, "Text");
			expect(textNode.isEzflapWidget, false);
			expect(textNode.mapNamedParams.isEmpty, true);
			expect(textNode.arrPositionalParams.length, 1);

			AstNodeBase stringNodeBase = textNode.arrPositionalParams[0];
			expect(stringNodeBase is AstNodeZssParameterValue, true);
			expect((stringNodeBase as AstNodeZssParameterValue).valueNode is AstNodeLiteral, true, reason: "stringNodeBase is ${stringNodeBase.runtimeType}");

			AstNodeLiteral stringNode = stringNodeBase.valueNode as AstNodeLiteral;
			expect(stringNode.value, "hello world");
		}));

		test("AST test - scaffold with body", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Scaffold>
					<body->
						<Container>
							<child->
								<Text>
									<:0->
										hello: {{ hello }}, counter: {{ counter }}
									</:0->
								</Text>
							</child->
						</Container>
					</body->
				</Scaffold>	
			""");

			expect(maybeTag != null, true);
			Tag tag = svcZmlTransformer.transform(maybeTag!);

			AstNodeBase? maybeNode = svcZmlCompiler.tryGenerateAst(tag);
			expect(maybeNode != null, true);

			AstNodeBase nodeBase = maybeNode!;
			expect(nodeBase is AstNodeWrapper, true);
			AstNodeWrapper nodeWrapper = nodeBase as AstNodeWrapper;

			AstNodeConstructor nodeScaffold = nodeWrapper.rootConstructorNode;
			expect(nodeScaffold.name, "Scaffold");
			expect(nodeScaffold.isEzflapWidget, false);
			expect(nodeScaffold.arrPositionalParams, [ ]);
			expect(nodeScaffold.mapNamedParams.length, 1);
			expect(nodeScaffold.mapNamedParams.containsKey("body"), true);

			AstNodeBase? maybeBodyNodeBase = nodeScaffold.mapNamedParams["body"];
			expect(maybeBodyNodeBase != null, true);
			expect(maybeBodyNodeBase is AstNodeZssParameterValue, true);
			expect((maybeBodyNodeBase as AstNodeZssParameterValue).valueNode is AstNodeConstructor, true);

			AstNodeConstructor bodyNodeBase = maybeBodyNodeBase.valueNode as AstNodeConstructor;
			expect(bodyNodeBase.name, "Container");
			expect(bodyNodeBase.isEzflapWidget, false);
			expect(bodyNodeBase.mapNamedParams.containsKey("child"), true);

			AstNodeBase? maybeTextNode = bodyNodeBase.mapNamedParams["child"];
			expect(maybeTextNode != null, true);
			expect(maybeTextNode is AstNodeZssParameterValue, true);
			expect((maybeTextNode as AstNodeZssParameterValue).valueNode is AstNodeConstructor, true);

			AstNodeConstructor textNode = maybeTextNode.valueNode as AstNodeConstructor;
			expect(textNode.isEzflapWidget, false);

			AstNodeBase stringNodeBase = textNode.arrPositionalParams[0];
			expect(stringNodeBase is AstNodeZssParameterValue, true);
			expect((stringNodeBase as AstNodeZssParameterValue).valueNode is AstNodeLiteral, true);

			AstNodeLiteral stringNode = stringNodeBase.valueNode as AstNodeLiteral;
			expect(stringNode.value, "hello: {{ hello }}, counter: {{ counter }}");
		});

		test("AST test - z-if", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<children->
						<Text><:0->text 1</:0-></Text>
						<Text z-if="shouldRenderText2"><:0->text 2</:0-></Text>
					</children->
				</Column>	
			""");

			expect(maybeTag != null, true);
			Tag tag = svcZmlTransformer.transform(maybeTag!);

			AstNodeBase? maybeNode = svcZmlCompiler.tryGenerateAst(tag);
			expect(maybeNode != null, true);

			AstNodeBase nodeBase = maybeNode!;
			expect(nodeBase is AstNodeWrapper, true);

			AstNodeConstructor nodeColumn = (nodeBase as AstNodeWrapper).rootConstructorNode;
			expect(nodeColumn.name, "Column");
			expect(nodeColumn.isEzflapWidget, false);
			expect(nodeColumn.conditionLiteral, null);
			expect(nodeColumn.mapNamedParams.length, 1);
			expect(nodeColumn.mapNamedParams.containsKey("children"), true);
			expect(nodeColumn.mapNamedParams["children"] is AstNodeZssParameterValue, true);

			AstNodeConstructorsList nodeConstructorsList = nodeColumn.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList;
			expect(nodeConstructorsList.arrConstructorNodes.length, 2);
			expect(nodeConstructorsList.arrConstructorNodes[0] is AstNodeConstructor, true);
			expect(nodeConstructorsList.arrConstructorNodes[1] is AstNodeConstructor, true);
			expect((nodeConstructorsList.arrConstructorNodes[0] as AstNodeConstructor).isEzflapWidget, false);
			expect((nodeConstructorsList.arrConstructorNodes[1] as AstNodeConstructor).isEzflapWidget, false);

			AstNodeConstructor nodeText1 = nodeConstructorsList.arrConstructorNodes[0] as AstNodeConstructor;
			expect(nodeText1.name, "Text");
			expect(nodeText1.isEzflapWidget, false);
			expect(nodeText1.conditionLiteral, null);
			expect(nodeText1.arrPositionalParams.length, 1);
			expect(nodeText1.arrPositionalParams[0] is AstNodeZssParameterValue, true);
			expect(nodeText1.arrPositionalParams[0].valueNode is AstNodeLiteral, true);

			AstNodeLiteral nodeString1 = nodeText1.arrPositionalParams[0].valueNode as AstNodeLiteral;
			expect(nodeString1.value, "text 1");

			AstNodeConstructor nodeText2 = nodeConstructorsList.arrConstructorNodes[1] as AstNodeConstructor;
			expect(nodeText2.name, "Text");
			expect(nodeText2.isEzflapWidget, false);
			expect(nodeText2.conditionLiteral, "shouldRenderText2");
			expect(nodeText2.arrPositionalParams.length, 1);
			expect(nodeText2.arrPositionalParams[0] is AstNodeZssParameterValue, true);
			expect(nodeText2.arrPositionalParams[0].valueNode is AstNodeLiteral, true);

			AstNodeLiteral nodeString2 = nodeText2.arrPositionalParams[0].valueNode as AstNodeLiteral;
			expect(nodeString2.value, "text 2");
		});

		test("AST test - ZGroup", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<children->
						<ZGroup z-if="groupTest1a || groupTest1b">
							<Text><:0->text 1</:0-></Text>
							<Text z-if="shouldRenderText2"><:0->text 2</:0-></Text>
							<ZGroup>
								<Text><:0->text 3</:0-></Text>
							</ZGroup>
							<ZGroup z-if="groupTest2" z-show="groupTestShow2">
							</ZGroup>
							<ZGroup z-if="groupTest3" z-show="groupTestShow3">
								<Text z-show="shouldRenderText4"><:0->text 4</:0-></Text>
							</ZGroup>
							<Column>
								<children->
									<ZGroup z-if="groupTest4">
										<Text z-if="shouldRenderText5"><:0->text 5</:0-></Text>
									</ZGroup>
									<ZGroup z-if="groupTest5">
										<ZGroup z-if="groupTest6">
											<Text z-if="shouldRenderText6"><:0->text 6</:0-></Text>
										</ZGroup>
										<Text z-for="item in arrItems" z-if="shouldInclude(item)">
											<:0->
												text 7
											</:0->
										</Text>
									</ZGroup>
								</children->
							</Column>
						</ZGroup>
					</children->
				</Column>	
			""");

			expect(maybeTag != null, true);
			Tag tag = svcZmlTransformer.transform(maybeTag!);

			AstNodeBase? maybeNode = svcZmlCompiler.tryGenerateAst(tag);
			expect(maybeNode != null, true);

			AstNodeBase nodeBase = maybeNode!;
			expect(nodeBase is AstNodeWrapper, true);

			AstNodeConstructor nodeColumn = (nodeBase as AstNodeWrapper).rootConstructorNode;
			expect(nodeColumn.name, "Column");
			expect(nodeColumn.isEzflapWidget, false);
			expect(nodeColumn.conditionLiteral, null);
			expect(nodeColumn.mapNamedParams.length, 1);
			expect(nodeColumn.mapNamedParams.containsKey("children"), true);
			expect(nodeColumn.mapNamedParams["children"]!.valueNode is AstNodeConstructorsList, true);

			AstNodeConstructorsList nodeConstructorsList = nodeColumn.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList;
			expect(nodeConstructorsList.arrConstructorNodes.length, 5);
			for (int i = 0; i < 5; i++) {
				expect(nodeConstructorsList.arrConstructorNodes[i] is AstNodeConstructor, true);
				expect((nodeConstructorsList.arrConstructorNodes[i] as AstNodeConstructor).isEzflapWidget, false);
			}

			_testText((nodeConstructorsList.arrConstructorNodes[0]) as AstNodeConstructor, "text 1", "((groupTest1a || groupTest1b))", null, null);
			_testText((nodeConstructorsList.arrConstructorNodes[1]) as AstNodeConstructor, "text 2", "((groupTest1a || groupTest1b))", "shouldRenderText2", null);
			_testText((nodeConstructorsList.arrConstructorNodes[2]) as AstNodeConstructor, "text 3", "((groupTest1a || groupTest1b))", null, null);
			_testText((nodeConstructorsList.arrConstructorNodes[3]) as AstNodeConstructor, "text 4", "((groupTest1a || groupTest1b) && (groupTest3))", null, "groupTestShow3");

			AstNodeConstructor nodeColumn2 = nodeConstructorsList.arrConstructorNodes[4] as AstNodeConstructor;
			expect(nodeColumn2.name, "Column");
			expect(nodeColumn2.priorityConditionLiteral, "((groupTest1a || groupTest1b))");
			expect(nodeColumn2.conditionLiteral, null);
			expect(nodeColumn2.mapNamedParams.length, 1);
			expect(nodeColumn2.mapNamedParams.containsKey("children"), true);
			expect(nodeColumn2.mapNamedParams["children"]!.valueNode is AstNodeConstructorsList, true);

			AstNodeConstructorsList nodeConstructorsList2 = nodeColumn2.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList;
			expect(nodeConstructorsList2.arrConstructorNodes.length, 3);
			AstNodeConstructor nodeText5 = nodeConstructorsList2.arrConstructorNodes[0] as AstNodeConstructor;
			_testText(nodeText5, "text 5", "((groupTest4))", "shouldRenderText5", null);

			AstNodeConstructor nodeText6 = nodeConstructorsList2.arrConstructorNodes[1] as AstNodeConstructor;
			_testText(nodeText6, "text 6", "((groupTest5) && (groupTest6))", "shouldRenderText6", null);

			AstNodeConstructor nodeText7 = nodeConstructorsList2.arrConstructorNodes[2] as AstNodeConstructor;
			_testText(nodeText7, "text 7", "((groupTest5))", "shouldInclude(item)", null);
		});

		test("AST test - ZBuild", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<children->
						<Text>text 1</Text>
						<ZBuild z-build="make()" />
						<ZBuild z-builder="builder" />
						<ZBuild z-build="make()" z-builder="builder" />
						<ZBuild />
						<Container z-build="make()" />
						<Container z-builder="make()" />
					</children->
				</Column>	
			""");

			expect(maybeTag != null, true);
			Tag tag = svcZmlTransformer.transform(maybeTag!);

			AstNodeBase? maybeNode = svcLogger.invoke(() {
				return svcZmlCompiler.tryGenerateAst(tag);
			});
			expect(maybeNode != null, true);

			expect(svcLogger.hasLoggedErrors(), true);

			List<EzError> arrErrors = svcLogger.getLoggedErrors();
			expect(arrErrors.length, 4);
			expect(arrErrors[0].message.contains("has both [z-build] and [z-builder] attributes. [z-build] and [z-builder] are mutually-exclusive."), true);
			expect(arrErrors[1].message.contains("must have either a [z-build] or a [z-builder] attribute."), true);
			expect(arrErrors[2].message.contains("does not support the [z-build] and [z-builder] attribute (only <${Tag.TAG_Z_BUILD}> supports them)."), true);
			expect(arrErrors[3].message.contains("does not support the [z-build] and [z-builder] attribute (only <${Tag.TAG_Z_BUILD}> supports them)."), true);


			AstNodeBase nodeBase = maybeNode!;
			expect(nodeBase is AstNodeWrapper, true);

			AstNodeConstructor nodeColumn = (nodeBase as AstNodeWrapper).rootConstructorNode;
			expect(nodeColumn.name, "Column");

			AstNodeConstructorsList nodeConstructorsList = nodeColumn.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList;
			expect(nodeConstructorsList.arrConstructorNodes.length, 3);

			AstNodeConstructor nodeText = nodeConstructorsList.arrConstructorNodes[0] as AstNodeConstructor;
			expect(nodeText.name, "Text");

			AstNodeConstructor nodeBuild1 = nodeConstructorsList.arrConstructorNodes[1] as AstNodeConstructor;
			expect(nodeBuild1.isZBuild(), true);
			expect(nodeBuild1.zBuild, "make()");
			expect(nodeBuild1.zBuilder, null);

			AstNodeConstructor nodeBuild2 = nodeConstructorsList.arrConstructorNodes[2] as AstNodeConstructor;
			expect(nodeBuild2.isZBuild(), true);
			expect(nodeBuild2.zBuild, null);
			expect(nodeBuild2.zBuilder, "builder");
		});

		test("AST test - positional parameters", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Text :3="fourth positional" z-attr:third="third named" z-bind:2="third positional" z-bind:4="fifth positional" z-bind:fourth="fourth named">
					<:1->second positional</:1->
					<first->first named</first->
					<:0->first positional</:0->
					<second->second named</second->
					<:5->sixth positional</:5->
				</Text>	
			""");

			expect(maybeTag != null, true);
			Tag tag = svcZmlTransformer.transform(maybeTag!);

			AstNodeBase? maybeNode = svcLogger.invoke(() {
				return svcZmlCompiler.tryGenerateAst(tag);
			});

			svcLogger.printLoggedErrorsIfNeeded();

			expect(svcLogger.hasLoggedErrors(), false);
			expect(maybeNode != null, true);

			AstNodeBase nodeBase = maybeNode!;
			expect(nodeBase is AstNodeWrapper, true);

			AstNodeConstructor nodeText = (nodeBase as AstNodeWrapper).rootConstructorNode;
			expect(nodeText.name, "Text");

			expect(nodeText.mapNamedParams.length, 3);
			expect(nodeText.mapNamedParams.containsKey("first"), true);
			expect(nodeText.mapNamedParams.containsKey("second"), true);
			expect(nodeText.mapNamedParams.containsKey("fourth"), true);
			expect(nodeText.mapNamedParams["first"]!.valueNode is AstNodeLiteral, true);
			expect(nodeText.mapNamedParams["second"]!.valueNode is AstNodeLiteral, true);
			expect(nodeText.mapNamedParams["fourth"]!.valueNode is AstNodeLiteral, true);

			expect(nodeText.arrPositionalParams.length, 6);
			expect(nodeText.arrPositionalParams[0].valueNode is AstNodeLiteral, true);
			expect(nodeText.arrPositionalParams[1].valueNode is AstNodeLiteral, true);
			expect(nodeText.arrPositionalParams[2].valueNode is AstNodeLiteral, true);
			expect(nodeText.arrPositionalParams[3].valueNode is AstNodeStringWithMustache, true);
			expect(nodeText.arrPositionalParams[4].valueNode is AstNodeLiteral, true);
			expect(nodeText.arrPositionalParams[5].valueNode is AstNodeLiteral, true);
			expect((nodeText.arrPositionalParams[0].valueNode as AstNodeLiteral).value, "first positional");
			expect((nodeText.arrPositionalParams[1].valueNode as AstNodeLiteral).value, "second positional");
			expect((nodeText.arrPositionalParams[2].valueNode as AstNodeLiteral).value, "third positional");
			expect((nodeText.arrPositionalParams[3].valueNode as AstNodeStringWithMustache).value, "fourth positional");
			expect((nodeText.arrPositionalParams[4].valueNode as AstNodeLiteral).value, "fifth positional");
			expect((nodeText.arrPositionalParams[5].valueNode as AstNodeLiteral).value, "sixth positional");
		});

		test("AST test - slot errors", () {
			svcLogger.invoke(() {
				Tag? maybeTag = svcZmlParser.tryParse("""
					<Column>
						<ZSlotProvider></ZSlotProvider>
						<ZSlotProvider>
							<Text />
							<Text />
						</ZSlotProvider>
						<ZSlotProvider z-attr:hello="world">
							<Container />
						</ZSlotProvider>
						<ZSlotProvider z-bind:hello="world">
							<Container />
						</ZSlotProvider>
						<ZSlotProvider z-if="world">
							<Container />
						</ZSlotProvider>
						<ZSlotProvider z-show="world">
							<Container />
						</ZSlotProvider>
						
						<ZSlotConsumer></ZSlotConsumer>
						<ZSlotConsumer>
							<Text />
							<Text />
						</ZSlotConsumer>
						<ZSlotConsumer z-attr:hello="world">
							<Container />
						</ZSlotConsumer>
						<ZSlotConsumer z-bind:hello="world">
							<Container />
						</ZSlotConsumer>
						<ZSlotConsumer z-if="world">
							<Container />
						</ZSlotConsumer>
						<ZSlotConsumer z-show="world">
							<Container />
						</ZSlotConsumer>
					</Column>	
				""");

				expect(maybeTag != null, true);
				Tag tag = svcZmlTransformer.transform(maybeTag!);
				return svcZmlCompiler.tryGenerateAst(tag);
			});

			expect(svcLogger.hasLoggedErrors(), true);
			List<EzError> arrErrors = svcLogger.getLoggedErrors();
			expect(arrErrors.length, 14);
			expect(arrErrors.where((x) => x.message == "Tag <ZSlotProvider> is a slot provider, and must have one or more unnamed children tags.").length, 1);
			expect(arrErrors.where((x) => x.message == "Tag <ZSlotProvider> is a slot provider, and cannot have named or positional parameters.").length, 2);
			expect(arrErrors.where((x) => x.message == "Tag <ZSlotProvider> is a slot provider or consumer, and cannot have [z-if].").length, 1);
			expect(arrErrors.where((x) => x.message == "Tag <ZSlotProvider> is a slot provider or consumer, and cannot have [z-show].").length, 1);
			expect(arrErrors.where((x) => x.message == "Tag <ZSlotConsumer> is a slot provider or consumer, and cannot have [z-if].").length, 1);
			expect(arrErrors.where((x) => x.message == "Tag <ZSlotConsumer> is a slot provider or consumer, and cannot have [z-show].").length, 1);
			expect(arrErrors.where((x) => x.message == "Tag [<Column>] is not an ezFlap widget and so cannot have ZSlotProvider tags.").length, 6);
		});

		test("AST test - slots", () {
			AstNodeWrapper? maybeNode = svcLogger.invoke(() {
				Tag? maybeTag = svcZmlParser.tryParse("""
					<ZmlCompilerTestSlotsExtendEzStatefulWidget>
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
					</ZmlCompilerTestSlotsExtendEzStatefulWidget>	
				""");

				expect(maybeTag != null, true);
				Tag tag = svcZmlTransformer.transform(maybeTag!);
				return svcZmlCompiler.tryGenerateAst(tag);
			});

			svcLogger.printLoggedErrorsIfNeeded();

			expect(svcLogger.hasLoggedErrors(), false);
			AstNodeConstructor widget = maybeNode!.rootConstructorNode;
			expect(widget.name, "ZmlCompilerTestSlotsExtendEzStatefulWidget");
			expect(widget.mapNamedParams.length, 1);
			expect(widget.mapNamedParams.containsKey("children"), true);
			expect(widget.mapNamedParams["children"]!.valueNode is AstNodeConstructorsList, true, reason: "type is: ${widget.mapNamedParams["children"]!.valueNode.runtimeType}");

			expect(widget.mapSlotProviders.length, 3);
			Map<String?, String> mapForProviders = {
				null: "\"\"\"provider: anonymous\"\"\"",
				"provider1": "\"\"\"provider: one\"\"\"",
				"provider2": "\"\"\"provider: two\"\"\"",
			};
			List<MapEntry<String?, String>> arrEntries = mapForProviders.entries.toList();
			for (int i = 0; i < mapForProviders.length; i++) {
				MapEntry<String?, String> kvp = arrEntries[i];
				expect(widget.mapSlotProviders.containsKey(kvp.key), true);

				AstNodeSlotProvider provider = widget.mapSlotProviders[kvp.key]!;
				expect(provider.name, kvp.key);
				expect(provider.childList.arrConstructorNodes.length, 1);
				expect(provider.childList.arrConstructorNodes[0] is AstNodeConstructor, true);

				AstNodeConstructor child = provider.childList.arrConstructorNodes[0] as AstNodeConstructor;
				expect(child.name, "Text");
				expect(child.arrPositionalParams.length, 1);
				expect(child.arrPositionalParams[0].valueNode is AstNodeLiteral, true);
				expect((child.arrPositionalParams[0].valueNode as AstNodeLiteral).value, kvp.value);
			}


			AstNodeConstructorsList listNode = widget.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList;
			expect(listNode.arrConstructorNodes.length, 3);
			Map<String?, String> mapForConsumers = {
				null: "\"\"\"consumer: anonymous\"\"\"",
				"consumer1": "\"\"\"consumer: one\"\"\"",
				"consumer2": "\"\"\"consumer: two\"\"\"",
			};
			arrEntries = mapForConsumers.entries.toList();
			for (int i = 0; i < mapForConsumers.length; i++) {
				MapEntry<String?, String> kvp = arrEntries[i];

				expect(listNode.arrConstructorNodes[i] is AstNodeSlotConsumer, true, reason: "type is: ${listNode.arrConstructorNodes[i].runtimeType}");

				AstNodeSlotConsumer consumer = listNode.arrConstructorNodes[i] as AstNodeSlotConsumer;
				expect(consumer.name, kvp.key);
				expect(consumer.defaultChildList != null, true);
				expect(consumer.defaultChildList!.arrConstructorNodes.length, 1);
				expect(consumer.defaultChildList!.arrConstructorNodes[0] is AstNodeConstructor, true);

				AstNodeConstructor child = consumer.defaultChildList!.arrConstructorNodes[0] as AstNodeConstructor;
				expect(child.name, "Text");
				expect(child.arrPositionalParams.length, 1);
				expect(child.arrPositionalParams[0].valueNode is AstNodeLiteral, true);
				expect((child.arrPositionalParams[0].valueNode as AstNodeLiteral).value, kvp.value);
			}
		});

		test("AST test - custom constructor name", () {
			AstNodeWrapper? maybeNode = svcLogger.invoke(() {
				Tag? maybeTag = svcZmlParser.tryParse("""
					<Column>
						<Text z-constructor="rich">
							<:0->
								<TextSpan>
									<text->
										hello world
									</text->
								</TextSpan>
							</:0->
						</Text>
					</Column>
				""");

				expect(maybeTag != null, true);
				Tag tag = svcZmlTransformer.transform(maybeTag!);
				return svcZmlCompiler.tryGenerateAst(tag);
			});

			svcLogger.printLoggedErrorsIfNeeded();

			expect(svcLogger.hasLoggedErrors(), false);
			AstNodeConstructor column = maybeNode!.rootConstructorNode;
			expect(column.name, "Column");
			expect(column.mapNamedParams.containsKey("children"), true);
			expect(column.mapNamedParams["children"]!.valueNode is AstNodeConstructorsList, true);
			expect((column.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList).arrConstructorNodes.length, 1);
			expect((column.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList).arrConstructorNodes[0] is AstNodeConstructor, true);

			AstNodeConstructor text = (column.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList).arrConstructorNodes[0] as AstNodeConstructor;
			expect(text.name, "Text");
			expect(text.customConstructorName, "rich");
		});

		test("AST test - z-key", () {
			AstNodeWrapper? maybeNode = svcLogger.invoke(() {
				Tag? maybeTag = svcZmlParser.tryParse("""
					<Column>
						<Container z-key="helloWorld" />
					</Column>
				""");

				expect(maybeTag != null, true);
				Tag tag = svcZmlTransformer.transform(maybeTag!);
				return svcZmlCompiler.tryGenerateAst(tag);
			});

			svcLogger.printLoggedErrorsIfNeeded();

			expect(svcLogger.hasLoggedErrors(), false);
			AstNodeConstructor column = maybeNode!.rootConstructorNode;
			expect(column.name, "Column");
			expect(column.mapNamedParams.containsKey("children"), true);
			expect(column.mapNamedParams["children"]!.valueNode is AstNodeConstructorsList, true);
			expect((column.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList).arrConstructorNodes.length, 1);
			expect((column.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList).arrConstructorNodes[0] is AstNodeConstructor, true);

			AstNodeConstructor container = (column.mapNamedParams["children"]!.valueNode as AstNodeConstructorsList).arrConstructorNodes[0] as AstNodeConstructor;
			expect(container.name, "Container");
			expect(container.zKey, "helloWorld");
		});

		test("AST test - mutually-exclusive children in a single-child parameter", () {
			AstNodeWrapper? maybeNode = svcLogger.invoke(() {
				Tag? maybeTag = svcZmlParser.tryParse("""
					<Container>
						<Container z-if="test1" />
						<Container z-if="test2" />
						<Container z-if="test3" />
					</Container>
				""");

				expect(maybeTag != null, true);
				Tag tag = svcZmlTransformer.transform(maybeTag!);
				return svcZmlCompiler.tryGenerateAst(tag);
			});

			svcLogger.printLoggedErrorsIfNeeded();

			expect(svcLogger.hasLoggedErrors(), false);
			AstNodeConstructor container = maybeNode!.rootConstructorNode;
			expect(container.name, "Container");
			expect(container.mapNamedParams.containsKey("child"), true);
			expect(container.mapNamedParams["child"]!.valueNode is AstNodeMutuallyExclusiveConstructorsList, true);
			expect((container.mapNamedParams["child"]!.valueNode as AstNodeMutuallyExclusiveConstructorsList).arrConstructorNodes.length, 3);
			expect((container.mapNamedParams["child"]!.valueNode as AstNodeMutuallyExclusiveConstructorsList).arrConstructorNodes[0] is AstNodeConstructor, true);
			expect((container.mapNamedParams["child"]!.valueNode as AstNodeMutuallyExclusiveConstructorsList).arrConstructorNodes[1] is AstNodeConstructor, true);
			expect((container.mapNamedParams["child"]!.valueNode as AstNodeMutuallyExclusiveConstructorsList).arrConstructorNodes[2] is AstNodeConstructor, true);

			AstNodeConstructor subContainer = (container.mapNamedParams["child"]!.valueNode as AstNodeMutuallyExclusiveConstructorsList).arrConstructorNodes[0] as AstNodeConstructor;
			expect(subContainer.name, "Container");
			expect(subContainer.conditionLiteral, "test1");
		});
	});
}

void _testText(AstNodeConstructor node, String text, String? priorityIfLiteral, String? ifLiteral, String? showLiteral) {
	expect(node.name, "Text");
	expect(node.priorityConditionLiteral, priorityIfLiteral);
	expect(node.conditionLiteral, ifLiteral);
	expect(node.arrPositionalParams.length, 1);
	expect(node.arrPositionalParams[0].valueNode is AstNodeLiteral, true);

	AstNodeLiteral nodeString = node.arrPositionalParams[0].valueNode as AstNodeLiteral;
	expect(nodeString.value, text);
}

void Function() withLogger(void Function() func) {
	return () {
		SvcLogger.i().invoke(() {
			func();
		});
	};
}
