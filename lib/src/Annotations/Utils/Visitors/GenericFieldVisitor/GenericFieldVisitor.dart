
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:ezflap/src/Annotations/Utils/Visitors/GenericFieldVisitor/Mixin/GenericFieldVisitorMixin.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/AST/TypeLiteralAstNodes.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/SvcTypeLiteralParser_.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class GenericFieldData {
	final FieldElement element;
	final String name;
	final String derivedName;
	final DartType type;
	final TypeLiteralAstNodeType typeNode;
	final String coreTypeName;
	final bool isLate;
	final bool isMarkedAsEzValue;
	final bool startsWithDontTouchPrefix;

	GenericFieldData({
		required this.element,
		required this.name,
		required this.derivedName,
		required this.type,
		required this.typeNode,
		required this.coreTypeName,
		required this.isLate,
		required this.isMarkedAsEzValue,
		required this.startsWithDontTouchPrefix,
	});

	bool isPrimitive() {
		return false
			|| this.type.isDartCoreString
			|| this.type.isDartCoreInt
			|| this.type.isDartCoreDouble
			|| this.type.isDartCoreBool
			|| this.type.isDartCoreNum
		;
	}

	bool isDynamic() => this.type.isDynamic;
	bool isSet() => (this.type.isDartCoreSet || this.coreTypeName == "RxSet");
	bool isList() => (this.type.isDartCoreList || this.coreTypeName == "RxList");
	bool isMap() => (this.type.isDartCoreMap || this.coreTypeName == "RxMap");
}

class GenericFieldVisitor extends SimpleElementVisitor with GenericFieldVisitorMixin {
	static const String _COMPONENT = "GenericFieldVisitor";

	SvcTypeLiteralParser get _svcTypeLiteralParser => SvcTypeLiteralParser.i();
	List<FieldElement> arrFieldElements = [ ];
	bool Function(GenericFieldData)? funcShouldIncludeField;

	GenericFieldVisitor([ this.funcShouldIncludeField ]);

	@override
	visitFieldElement(FieldElement element) {
		if (this.funcShouldIncludeField != null) {
			GenericFieldData? data = this._makeData(element);
			if (data == null) {
				// skip this one
				return;
			}

			if (this.funcShouldIncludeField!(data)) {
				this.arrFieldElements.add(element);
			}
		}
	}

	FieldElement? tryGetElementByName(String name) {
		return this.arrFieldElements.where((x) => x.name == name).firstOrNull();
	}

	List<GenericFieldData> getArrGenericFieldData() {
		return this.arrFieldElements
			.map((x) => this._makeData(x))
			.filterNull()
			.denull()
			.toList()
		;
	}

	GenericFieldData? _makeData(FieldElement element) {
		DartType type = element.type;

		// type.element?.name seems to be null when using typedef-ed types
		// after upgrade to 2.15.1.
		// if (type.element?.name == null) {
		// 	return null;
		// }
		//String coreTypeName = type.element!.name!;
		String coreTypeName = type.element?.name ?? type.toString();

		String name = element.name;
		String derivedName = this.getDerivedName(element);
		TypeLiteralAstNodeType typeLiteralAstNodeType = this._svcTypeLiteralParser.parseDartType(type);
		bool isLate = this.getIsLate(element);
		bool isMarkedAsEzValue = this.isMarkedAsEzValue(element);
		bool startsWithDontTouchPrefix = this.doesStartWithDontTouchPrefix(element);

		return GenericFieldData(
			element: element,
			name: name,
			derivedName: derivedName,
			type: type,
			typeNode: typeLiteralAstNodeType,
			coreTypeName: coreTypeName,
			isLate: isLate,
			isMarkedAsEzValue: isMarkedAsEzValue,
			startsWithDontTouchPrefix: startsWithDontTouchPrefix,
		);
	}
}