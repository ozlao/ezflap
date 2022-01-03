
import 'package:ezflap/src/Service/Error/SvcLogger_.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/AST/TypeLiteralAstNodes.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/SvcTypeLiteralParser_.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	group("Testing SvcTypeLiteralParser", () {
		SvcLogger svcLogger = SvcLogger.i();
		SvcTypeLiteralParser svcTypeLiteralParser = SvcTypeLiteralParser.i();

		test("Type literal parse test - non-generics", () {
			TypeLiteralAstNodeType astRoot;

			astRoot = svcTypeLiteralParser.parseTypeLiteral("int");
			expect(astRoot.name, "int");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isNullable, false);
			expect(astRoot.getFullName(), "int");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("String");
			expect(astRoot.name, "String");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isNullable, false);
			expect(astRoot.getFullName(), "String");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("double");
			expect(astRoot.name, "double");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isNullable, false);

			astRoot = svcTypeLiteralParser.parseTypeLiteral("MyClass");
			expect(astRoot.name, "MyClass");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isNullable, false);
			expect(astRoot.getFullName(), "MyClass");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("MyClass?");
			expect(astRoot.name, "MyClass");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isMap(), false);
			expect(astRoot.isRxMap(), false);
			expect(astRoot.isMapLike(), false);
			expect(astRoot.isNullable, true);
			expect(astRoot.getFullName(), "MyClass?");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("Map");
			expect(astRoot.name, "Map");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isMap(), true);
			expect(astRoot.isRxMap(), false);
			expect(astRoot.isMapLike(), true);

			astRoot = svcTypeLiteralParser.parseTypeLiteral("List");
			expect(astRoot.name, "List");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isList(), true);
			expect(astRoot.isRxList(), false);
			expect(astRoot.isListLike(), true);

			astRoot = svcTypeLiteralParser.parseTypeLiteral("RxMap");
			expect(astRoot.name, "RxMap");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isMap(), false);
			expect(astRoot.isRxMap(), true);
			expect(astRoot.isMapLike(), true);

			astRoot = svcTypeLiteralParser.parseTypeLiteral("RxList");
			expect(astRoot.name, "RxList");
			expect(astRoot.arrGenericNodes.length, 0);
			expect(astRoot.isList(), false);
			expect(astRoot.isRxList(), true);
			expect(astRoot.isListLike(), true);
		});

		test("Type literal parse test - single-level generics", () {
			TypeLiteralAstNodeType astRoot;

			astRoot = svcTypeLiteralParser.parseTypeLiteral("MyClass<int>");
			expect(astRoot.name, "MyClass");
			expect(astRoot.isNullable, false);
			expect(astRoot.getFullName(), "MyClass<int>");
			expect(astRoot.arrGenericNodes.length, 1);
			expect(astRoot.arrGenericNodes[0].name, "int");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[0].getFullName(), "int");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("List<String>?");
			expect(astRoot.name, "List");
			expect(astRoot.isList(), true);
			expect(astRoot.isNullable, true);
			expect(astRoot.getFullName(), "List<String>?");
			expect(astRoot.arrGenericNodes.length, 1);
			expect(astRoot.arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[0].getFullName(), "String");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("List<List?>?");
			expect(astRoot.name, "List");
			expect(astRoot.isList(), true);
			expect(astRoot.isNullable, true);
			expect(astRoot.getFullName(), "List<List?>?");
			expect(astRoot.arrGenericNodes.length, 1);
			expect(astRoot.arrGenericNodes[0].name, "List");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), true);
			expect(astRoot.arrGenericNodes[0].isNullable, true);
			expect(astRoot.arrGenericNodes[0].getFullName(), "List?");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("Map<String, int>");
			expect(astRoot.name, "Map");
			expect(astRoot.isMap(), true);
			expect(astRoot.isNullable, false);
			expect(astRoot.getFullName(), "Map<String, int>");
			expect(astRoot.arrGenericNodes.length, 2);
			expect(astRoot.arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[0].getFullName(), "String");
			expect(astRoot.arrGenericNodes[1].name, "int");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[1].isList(), false);
			expect(astRoot.arrGenericNodes[1].isNullable, false);
			expect(astRoot.arrGenericNodes[1].getFullName(), "int");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("Map<String?, List?>?");
			expect(astRoot.name, "Map");
			expect(astRoot.isMap(), true);
			expect(astRoot.isNullable, true);
			expect(astRoot.getFullName(), "Map<String?, List?>?");
			expect(astRoot.arrGenericNodes.length, 2);
			expect(astRoot.arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[0].isNullable, true);
			expect(astRoot.arrGenericNodes[0].getFullName(), "String?");
			expect(astRoot.arrGenericNodes[1].name, "List");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[1].isList(), true);
			expect(astRoot.arrGenericNodes[1].isNullable, true);
			expect(astRoot.arrGenericNodes[1].getFullName(), "List?");
		});

		test("Type literal parse test - two-level generics", () {
			TypeLiteralAstNodeType astRoot;

			astRoot = svcTypeLiteralParser.parseTypeLiteral("Map<String?, List<String>>?");
			expect(astRoot.name, "Map");
			expect(astRoot.isMap(), true);
			expect(astRoot.isNullable, true);
			expect(astRoot.getFullName(), "Map<String?, List<String>>?");
			expect(astRoot.arrGenericNodes.length, 2);
			expect(astRoot.arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[0].isNullable, true);
			expect(astRoot.arrGenericNodes[0].getFullName(), "String?");
			expect(astRoot.arrGenericNodes[1].name, "List");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes.length, 1);
			expect(astRoot.arrGenericNodes[1].isList(), true);
			expect(astRoot.arrGenericNodes[1].isNullable, false);
			expect(astRoot.arrGenericNodes[1].getFullName(), "List<String>");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].getFullName(), "String");

			astRoot = svcTypeLiteralParser.parseTypeLiteral("Map<String?, List<String>?>?");
			expect(astRoot.name, "Map");
			expect(astRoot.isMap(), true);
			expect(astRoot.isNullable, true);
			expect(astRoot.getFullName(), "Map<String?, List<String>?>?");
			expect(astRoot.arrGenericNodes.length, 2);
			expect(astRoot.arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[0].isNullable, true);
			expect(astRoot.arrGenericNodes[0].getFullName(), "String?");
			expect(astRoot.arrGenericNodes[1].name, "List");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes.length, 1);
			expect(astRoot.arrGenericNodes[1].isList(), true);
			expect(astRoot.arrGenericNodes[1].isNullable, true);
			expect(astRoot.arrGenericNodes[1].getFullName(), "List<String>?");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].getFullName(), "String");
		});

		test("Type literal parse test - three-level generics", () {
			TypeLiteralAstNodeType astRoot;

			astRoot = svcTypeLiteralParser.parseTypeLiteral("Map<String, List<Map<String, String>>>");
			expect(astRoot.name, "Map");
			expect(astRoot.isMap(), true);
			expect(astRoot.isNullable, false);
			expect(astRoot.getFullName(), "Map<String, List<Map<String, String>>>");
			expect(astRoot.arrGenericNodes.length, 2);
			expect(astRoot.arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[0].isList(), false);
			expect(astRoot.arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[0].getFullName(), "String");
			expect(astRoot.arrGenericNodes[1].name, "List");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes.length, 1);
			expect(astRoot.arrGenericNodes[1].isList(), true);
			expect(astRoot.arrGenericNodes[1].isNullable, false);
			expect(astRoot.arrGenericNodes[1].getFullName(), "List<Map<String, String>>");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].name, "Map");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes.length, 2);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].isMap(), true);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].getFullName(), "Map<String, String>");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[0].name, "String");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[0].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[0].isMap(), false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[0].isNullable, false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[0].getFullName(), "String");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[1].name, "String");
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[1].arrGenericNodes.length, 0);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[1].isMap(), false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[1].isNullable, false);
			expect(astRoot.arrGenericNodes[1].arrGenericNodes[0].arrGenericNodes[1].getFullName(), "String");
		});
	});
}
