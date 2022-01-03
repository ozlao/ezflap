
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Utils/EzError/EzError.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	group("Testing SvcZmlParser", () {
		SvcLogger svcLogger = SvcLogger.i();
		SvcZmlParser svcZmlParser = SvcZmlParser.i();

		test("Parse test 1", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Container></Container>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Container");
			expect(tag.arrUnnamedChildren.length, 0);
		});

		test("Parse test 2", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Container><Text>hello world</Text></Container>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Container");
			expect(tag.arrUnnamedChildren.length, 1);
			expect(tag.arrUnnamedChildren[0].name, "Text");
			expect(tag.arrUnnamedChildren[0].text, "hello world");
		});

		test("Parse test - all attributes", () {
			Tag? maybeTag = svcLogger.invoke(() {
				return svcZmlParser.tryParse("""
					<Container
						class="my class"
						z-if="my z-if"
						z-show="my z-show"
						z-for="book in arrBooks"
						z-ref="my z-ref"
						z-build="my z-build"
						z-builder="my z-builder"
						z-name="my z-name"
						literal1="my literal 1"
						literal2="my literal 2"
						z-bind:eval1="my eval 1"
						z-bind:eval2="my eval 2"
						z-on:on1="my on 1"
						z-on:on2="my on 2"
						z-model="my z-model"
						z-model:model1="my model 1"
						z-model:model2="my model 2"
					/>
				""");
			});

			expect(svcLogger.hasLoggedErrors(), false);
			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Container");
			expect(tag.arrUnnamedChildren.length, 0);
			expect(tag.stringAttrClass, "my class", reason: "class");
			expect(tag.zIf, "my z-if", reason: "z-if");
			expect(tag.zShow, "my z-show", reason: "z-show");
			expect(tag.zFor != null, true, reason: "z-for");
			expect(tag.zRef, "my z-ref", reason: "z-ref");
			expect(tag.zBuild, "my z-build", reason: "z-build");
			expect(tag.zBuilder, "my z-builder", reason: "z-builder");
			expect(tag.zName, "my z-name", reason: "z-name");
			expect(tag.mapStrings.length, 2, reason: "mapLiterals: ${tag.mapStrings}");
			expect(tag.mapStrings.values.toList()[0], "my literal 1", reason: "literal 1");
			expect(tag.mapStrings.values.toList()[1], "my literal 2", reason: "literal 2");
			expect(tag.mapZBinds.length, 2, reason: "mapZBinds");
			expect(tag.mapZBinds["eval1"], "my eval 1", reason: "eval 1");
			expect(tag.mapZBinds["eval2"], "my eval 2", reason: "eval 2");
			expect(tag.mapZOns.length, 2, reason: "mapZOns");
			expect(tag.mapZOns["on1"], "my on 1", reason: "on 1");
			expect(tag.mapZOns["on2"], "my on 2", reason: "on 2");
			expect(tag.mapZModels.length, 3, reason: "mapZModels");
			expect(tag.mapZModels[SvcZmlParser.DEFAULT_MODEL_KEY], "my z-model", reason: "z-model");
			expect(tag.mapZModels["model1"], "my model 1", reason: "model 1");
			expect(tag.mapZModels["model2"], "my model 2", reason: "model 2");
		});

		test("Parse test - z-for", () {
			Tag? maybeTag = svcLogger.invoke(() {
				return svcZmlParser.tryParse("""
					<Container>
						<Column z-for="book in arrBooks"></Column>
						<Column z-for="(book, idx) in arrBooks"></Column>
						<Column z-for="(book, idx) in someClass.arrBooks"></Column>
						<Column z-for="(book, idx) in [ 'book1', 'book2' ]"></Column>
						<Column z-for="(book, idx) in { 'bk1': 'book1', 'bk2': 'book2' }"></Column>
						<Column z-for="invalid syntax"></Column>
					</Container>
				""");
			});

			expect(svcLogger.hasLoggedErrors(), true);
			List<EzError> arrErrors = svcLogger.getLoggedErrors();
			expect(arrErrors.length, 1, reason: "Expected a single error. Got: ${arrErrors}");
			expect(arrErrors[0].message.contains("Failed to parse z-for expression"), true);

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Container");
			expect(tag.arrUnnamedChildren.length, 6);
			expect(tag.arrUnnamedChildren[0].name, "Column");
			_testZFor(tag.arrUnnamedChildren[0], "book", null, null, "arrBooks");
			_testZFor(tag.arrUnnamedChildren[1], "book", "idx", null, "arrBooks");
			_testZFor(tag.arrUnnamedChildren[2], "book", "idx", null, "someClass.arrBooks");
			_testZFor(tag.arrUnnamedChildren[3], "book", "idx", null, "[ 'book1', 'book2' ]");
			_testZFor(tag.arrUnnamedChildren[4], "book", "idx", null, "{ 'bk1': 'book1', 'bk2': 'book2' }");
			expect(tag.arrUnnamedChildren[5].zFor, null, reason: "Failed to recognize syntax as invalid");
			expect(svcLogger.hasLoggedErrors(), true);
		});

		test("Parse test - named and unnamed parameter children", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<child1->hello world</child1->
					<child2-><Container></Container></child2->
					<child3-></child3->
					<Container class="container1"></Container>
					<Container class="container2"></Container>
				</Column>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 2);
			expect(tag.arrUnnamedChildren[0].name, "Container");
			expect(tag.arrUnnamedChildren[0].stringAttrClass, "container1");
			expect(tag.arrUnnamedChildren[1].name, "Container");
			expect(tag.arrUnnamedChildren[1].stringAttrClass, "container2");

			expect(tag.mapNamedChildren.length, 3);

			Tag? child1 = tag.mapNamedChildren["child1"];
			expect(child1?.text, "hello world");
			expect(child1!.isNamedChildTag, true);
			expect(child1.name, "child1");

			Tag? child2 = tag.mapNamedChildren["child2"];
			expect(child2?.arrUnnamedChildren[0].name, "Container");
			expect(child2!.isNamedChildTag, true);
			expect(child2.name, "child2");

			Tag? child3 = tag.mapNamedChildren["child3"];
			expect(child3 != null, true);
			expect(child3!.text, "");
			expect(child3.isNamedChildTag, true);
			expect(child3.name, "child3");
		});

		test("Parse test - scaffold with body", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Scaffold>
					<body->
						<Container>
							<Text>hello: {{ hello }}, counter: {{ counter }}</Text>
						</Container>
					</body->
				</Scaffold>	
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Scaffold");
			expect(tag.arrUnnamedChildren.length, 0);

			expect(tag.mapNamedChildren.length, 1);

			Tag? maybeBody = tag.mapNamedChildren["body"];
			expect(maybeBody != null, true);

			Tag body = maybeBody!;
			expect(body.arrUnnamedChildren.length, 1);

			Tag container = body.arrUnnamedChildren[0];
			expect(container.arrUnnamedChildren.length, 1);

			Tag text = container.arrUnnamedChildren[0];
			expect(text.text, "hello: {{ hello }}, counter: {{ counter }}");
		});

		test("Parse test - test comments", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<Text>hello world - in</Text>
					<_Text>hello world - out</_Text>
					<Scaffold>
						<_body->
							<Text>body (comment)</Text>
						</_body->
						<_another->
							<Text>another (comment)</Text>
						</_another->
						<body->
							<Text>body (real)</Text>
						</body->
					</Scaffold>
					<Container
						_z-if="false"
						z-if="true"
						_z-bind:myEval1="var1"
						z-bind:myEval2="var2"
					/>
				</Column>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 3);

			Tag tagText = tag.arrUnnamedChildren[0];
			expect(tagText.name, "Text");
			expect(tagText.text, "hello world - in");

			Tag tagScaffold = tag.arrUnnamedChildren[1];
			expect(tagScaffold.arrUnnamedChildren.isEmpty, true);
			expect(tagScaffold.mapNamedChildren.length, 1);
			expect(tagScaffold.mapNamedChildren.containsKey("body"), true);

			Tag tagBody = tagScaffold.mapNamedChildren["body"]!;
			expect(tagBody.isNamedChildTag, true);
			expect(tagBody.arrUnnamedChildren.length, 1);

			Tag tagBodyText = tagBody.arrUnnamedChildren[0];
			expect(tagBodyText.name, "Text");
			expect(tagBodyText.text, "body (real)");

			Tag tagContainer = tag.arrUnnamedChildren[2];
			expect(tagContainer.name, "Container");
			expect(tagContainer.zIf, "true");
			expect(tagContainer.mapZBinds.length, 1);
			expect(tagContainer.mapZBinds["myEval2"], "var2");
		});

		test("Parse test - ZGroup", () {
			Tag? maybeTag = svcLogger.invoke(() {
				return svcZmlParser.tryParse("""
					<Container>
						<ZGroup>
							<Column z-for="book in arrBooks"></Column>
							<Column z-for="(book, idx) in arrBooks"></Column>
							<Column z-for="(book, idx) in someClass.arrBooks"></Column>
							<Column z-for="(book, idx) in [ 'book1', 'book2' ]"></Column>
							<Column z-for="(book, idx) in { 'bk1': 'book1', 'bk2': 'book2' }"></Column>
						</ZGroup>
					</Container>
				""");
			});

			expect(maybeTag != null, true);
			Tag containerTag = maybeTag!;
			expect(containerTag.name, "Container");
			expect(containerTag.arrUnnamedChildren.length, 1);

			Tag tag = containerTag.arrUnnamedChildren[0];
			expect(tag.isTypeGroup(), true);

			expect(tag.arrUnnamedChildren.length, 5);
			expect(tag.arrUnnamedChildren[0].name, "Column");
			_testZFor(tag.arrUnnamedChildren[0], "book", null, null, "arrBooks");
			_testZFor(tag.arrUnnamedChildren[1], "book", "idx", null, "arrBooks");
			_testZFor(tag.arrUnnamedChildren[2], "book", "idx", null, "someClass.arrBooks");
			_testZFor(tag.arrUnnamedChildren[3], "book", "idx", null, "[ 'book1', 'book2' ]");
			_testZFor(tag.arrUnnamedChildren[4], "book", "idx", null, "{ 'bk1': 'book1', 'bk2': 'book2' }");
		});

		test("Parse test - positional parameters", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Text z-attr:3="fourth positional" z-attr:third="third named" z-bind:2="third positional" z-bind:4="fifth positional" z-bind:fourth="fourth named">
					<:1->second positional</:1->
					<first->first named</first->
					<:0->first positional</:0->
					<second->second named</second->
					<:5->sixth positional</:5->
				</Text>	
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Text");
			expect(tag.arrUnnamedChildren.length, 0);

			expect(tag.mapNamedChildren.length, 5);
			expect(tag.mapNamedChildren.containsKey(":1"), true);
			expect(tag.mapNamedChildren.containsKey("first"), true);
			expect(tag.mapNamedChildren.containsKey(":0"), true);
			expect(tag.mapNamedChildren.containsKey("second"), true);
			expect(tag.mapNamedChildren.containsKey(":5"), true);
		});

		test("Parse test - comment", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<Container />
					<!-- hello world -->
					<Container />
				</Column>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 2);
			expect(tag.mapNamedChildren.length, 0);
			expect(tag.text, "<!-- hello world -->");
		});

		test("Parse test - custom constructor", () {
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
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 1);
			expect(tag.arrUnnamedChildren[0].name, "Text");
			expect(tag.arrUnnamedChildren[0].zCustomConstructorName, "rich");
		});

		test("Parse test - z-key", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<Container z-key="helloWorld" />
				</Column>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 1);
			expect(tag.arrUnnamedChildren[0].zKey, "helloWorld");
		});

		test("Parse test - unescape ZML text", () {
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello world"), "hello world");

			expect(svcZmlParser.unescapeZmlTextForDisplay("hello world"), "hello world");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello  world"), "hello world");
			expect(svcZmlParser.unescapeZmlTextForDisplay("\\hello \\\\ wo\\rld\\"), "\\\\hello \\\\\\\\ wo\\\\rld\\\\");
			expect(svcZmlParser.unescapeZmlTextForDisplay("\"hello \"\" wo\"rld\""), "\\\"hello \\\"\\\" wo\\\"rld\\\"");
			expect(svcZmlParser.unescapeZmlTextForDisplay("\$hello \$\$ wo\$rld\$"), "\\\$hello \\\$\\\$ wo\\\$rld\\\$");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello <!-- some comment --> world"), "hello world");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello <!-- some {{ comment --> }} world"), "hello }} world");
			expect(
				svcZmlParser.unescapeZmlTextForDisplay(
					"""
						hello
							<!-- some comment -->
						world
					""",
					allowTrimLeft: true,
					allowTrimRight: true
				),
				"hello world"
			);
			expect(svcZmlParser.unescapeZmlTextForDisplay("&lt;hello &lt;&lt; wo&lt;rld&lt;"), "<hello << wo<rld<");
			expect(svcZmlParser.unescapeZmlTextForDisplay("&gt;hello &gt;&gt; wo&gt;rld&gt;"), ">hello >> wo>rld>");
			expect(svcZmlParser.unescapeZmlTextForDisplay("&amp;hello &amp;&amp; wo&amp;rld&amp;"), "&hello && wo&rld&");
			expect(svcZmlParser.unescapeZmlTextForDisplay("&nbsp;hello &nbsp;&nbsp; wo&nbsp;rld&nbsp;"), " hello  wo rld ");
			expect(svcZmlParser.unescapeZmlTextForDisplay("<br/>hello <br/><br/> wo<br/>rld<br/>"), "\nhello \n\nwo\nrld\n");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello &nbsp; world"), "hello world");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello   &nbsp;   world"), "hello world");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello   &nbsp;   world &nbsp;"), "hello world ");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello   &nbsp;   world   &nbsp;"), "hello world ");
			expect(svcZmlParser.unescapeZmlTextForDisplay("hello   &nbsp;   world   &nbsp;  "), "hello world ");
		});
	});
}

void _testZFor(Tag tag, String valueIter, String? keyOrIdxIter, String? keyIter, String collectionExpr) {
	expect(tag.zFor != null, true, reason: "tag ${tag} has no z-for");

	ZFor zFor = tag.zFor!;
	expect(zFor.iterKeyOrIdx, keyOrIdxIter, reason: "tag ${tag} has z-for iterKeyOrIdx [${zFor.iterKey}] different from [${keyIter}]");
	expect(zFor.iterKey, keyIter, reason: "tag ${tag} has z-for iterKey [${zFor.iterKey}] different from [${keyIter}]");
	expect(zFor.iterValue, valueIter, reason: "tag ${tag} has z-for iterValue [${zFor.iterValue}] different from [${valueIter}]");
	expect(zFor.collectionExpr, collectionExpr, reason: "tag ${tag} has z-for collectionExpr [${zFor.collectionExpr}] different from [${collectionExpr}]");
}