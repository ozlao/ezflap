
import 'package:ezflap/src/Service/Zml/Parser/SvcZmlParser_.dart';
import 'package:ezflap/src/Service/Zml/Parser/Tag/Tag.dart';
import 'package:ezflap/src/Service/Zml/Transformer/SvcZmlTransformer_.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../Reflector/Bootstrapper/ReflectorBootstrapper.dart';

SvcZmlTransformer svcZmlTransformer = SvcZmlTransformer.i();

void main() {
	group("Testing SvcZmlTransformer", () {
		SvcZmlParser svcZmlParser = SvcZmlParser.i();

		ReflectorBootstrapper.initReflectorForTesting();

		svcZmlTransformer.bootstrapDefaultTransformers();

		test("Transform test 1", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Container></Container>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Container");
			expect(tag.arrUnnamedChildren.length, 0);

			Tag transTag = svcZmlTransformer.transform(tag);
			expect(transTag.name, "Container");
			expect(transTag.arrUnnamedChildren.length, 0);
		});

		test("Transform - test ChildrenTransformer - single child", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Container>
					<Text>
						hello world
					</Text>
				</Container>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Container");
			expect(tag.arrUnnamedChildren.length, 1);

			Tag transTag = svcZmlTransformer.transform(tag);
			expect(transTag.name, "Container");
			expect(transTag.arrUnnamedChildren.length, 0);
			expect(transTag.mapNamedChildren.length, 1);
			expect(transTag.mapNamedChildren.containsKey("child"), true);

			Tag childParamTag = transTag.mapNamedChildren["child"]!;
			expect(childParamTag.name, "child");
			expect(childParamTag.arrUnnamedChildren.length, 1);

			Tag textTag = childParamTag.arrUnnamedChildren[0];
			expect(textTag.name, "Text");
		});

		test("Transform - test ChildrenTransformer - single child in [children]", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<Text>
						hello world
					</Text>
				</Column>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 1);

			Tag transTag = svcZmlTransformer.transform(tag);
			expect(transTag.name, "Column");
			expect(transTag.arrUnnamedChildren.length, 0);
			expect(transTag.mapNamedChildren.length, 1);
			expect(transTag.mapNamedChildren.containsKey("children"), true);

			Tag childrenParamTag = transTag.mapNamedChildren["children"]!;
			expect(childrenParamTag.name, "children");
			expect(childrenParamTag.arrUnnamedChildren.length, 1);

			Tag textTag = childrenParamTag.arrUnnamedChildren[0];
			expect(textTag.name, "Text");
		});

		test("Transform - test ChildrenTransformer - multiple children in [children]", () {
			Tag? maybeTag = svcZmlParser.tryParse("""
				<Column>
					<Text>
						hello world
					</Text>
					<Container />
					<Container />
				</Column>
			""");

			expect(maybeTag != null, true);
			Tag tag = maybeTag!;
			expect(tag.name, "Column");
			expect(tag.arrUnnamedChildren.length, 3);

			Tag transTag = svcZmlTransformer.transform(tag);
			expect(transTag.name, "Column");
			expect(transTag.arrUnnamedChildren.length, 0);
			expect(transTag.mapNamedChildren.length, 1);
			expect(transTag.mapNamedChildren.containsKey("children"), true);

			Tag childrenParamTag = transTag.mapNamedChildren["children"]!;
			expect(childrenParamTag.name, "children");
			expect(childrenParamTag.arrUnnamedChildren.length, 3);

			Tag textTag = childrenParamTag.arrUnnamedChildren[0];
			expect(textTag.name, "Text");

			Tag childContainerTag = childrenParamTag.arrUnnamedChildren[1];
			expect(childContainerTag.name, "Container");
		});

		test("Transform - test TextTransformer", () {
			Map<String, String> map = { };
			void Function(String, String) add = (source, target) => map[source] = target;

			add("hello world", "hello world");
			add("hello  world", "hello world");
			add("\\hello \\\\ wo\\rld\\", "\\\\hello \\\\\\\\ wo\\\\rld\\\\");
			add("\"hello \"\" wo\"rld\"", "\\\"hello \\\"\\\" wo\\\"rld\\\"");
			add("\$hello \$\$ wo\$rld\$", "\\\$hello \\\$\\\$ wo\\\$rld\\\$");
			add("hello <!-- some comment --> world", "hello world");
			add(
				"""
					hello
						<!-- some comment -->
					world
				""",
				"hello world"
			);
			add("&lt;hello &lt;&lt; wo&lt;rld&lt;", "<hello << wo<rld<");
			add("&gt;hello &gt;&gt; wo&gt;rld&gt;", ">hello >> wo>rld>");
			add("&amp;hello &amp;&amp; wo&amp;rld&amp;", "&hello && wo&rld&");
			add("&nbsp;hello &nbsp;&nbsp; wo&nbsp;rld&nbsp;", " hello  wo rld ");
			add("<br />hello <br/><br/> wo<br/>rld<br/>", "\nhello \n\nwo\nrld\n");
			add("hello {{   interpolate me }} world", "hello \${   interpolate me } world");
			add("hello &nbsp; world", "hello world");
			add("hello   &nbsp;   world", "hello world");
			add("hello   &nbsp;   world &nbsp;", "hello world ");
			add("hello   &nbsp;   world   &nbsp;", "hello world ");
			add("hello   &nbsp;   world   &nbsp;  ", "hello world ");

			for (MapEntry<String, String> kvp in map.entries) {
				String s = """
					<Text>
						${kvp.key}
					</Text>
				""";
				Tag tag = svcZmlParser.tryParse(s)!;

				testTextTransformation(tag, kvp.value);
			}
		});
	});
}

void testTextTransformation(Tag untransformedTextTag, String unwrappedExpected) {
	const String PREFIX = SvcZmlParser.CHILD_TAG_POSITIONAL_PARAMETER_PREFIX;

	Tag transformedTextTag = svcZmlTransformer.transform(untransformedTextTag);
	expect(transformedTextTag.name, "Text");
	expect(transformedTextTag.arrUnnamedChildren.length, 0);
	expect(transformedTextTag.mapNamedChildren.length, 1);

	String childName = "${PREFIX}0";
	expect(transformedTextTag.mapNamedChildren.containsKey(childName), true);

	Tag childParamTag = transformedTextTag.mapNamedChildren[childName]!;
	expect(childParamTag.name, childName);
	expect(childParamTag.mapNamedChildren.length, 0);
	expect(childParamTag.arrUnnamedChildren.length, 0);
	expect(childParamTag.text, "\"\"\"${unwrappedExpected}\"\"\"");
}