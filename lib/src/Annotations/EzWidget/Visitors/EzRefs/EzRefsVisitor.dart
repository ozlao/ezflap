
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzRefs/EzRefs.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/AST/TypeLiteralAstNodes.dart';
import 'package:ezflap/src/Service/Parser/TypeLiteral/SvcTypeLiteralParser_.dart';

class EzRefsData extends EzFieldDataBase {
	late final String keyType;
	late final String valueType;

	@override
	String toString() {
		return "EzRefsData: ${this.assignedName} (${this.typeWithNullability})";
	}
}

class EzRefsVisitor extends FieldElementVisitorBase<EzRefs, EzRefsData> {
	static const String _COMPONENT = "EzRefsVisitor";

	SvcTypeLiteralParser get _svcTypeLiteralParser { return SvcTypeLiteralParser.i(); }
	
	@override
	// ignore: avoid_renaming_method_parameters
	EzRefsData? makeData(EzRefs ezRefs, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String typeWithNullability = this.getType(element);

		String typeWithoutNullability = this.getTypeWithoutNullability(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		String keyType = this._getKeyType(element);
		String valueType = this._getValueType(element);
		bool isList = this.getIsList(element);

		return EzRefsData()
			..assignedName = ezRefs.name
			..derivedName = derivedName
			..typeWithNullability = typeWithNullability
			..typeWithoutNullability = typeWithoutNullability
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..keyType = keyType
			..valueType = valueType
			..isList = isList
		;
	}

	String _getKeyType(FieldElement element) {
		TypeLiteralAstNodeType? typeLiteralAstNodeType = this._getTypeLiteralAstNodeType(element);
		return typeLiteralAstNodeType?.arrGenericNodes[0].getFullName() ?? "String";
	}

	String _getValueType(FieldElement element) {
		TypeLiteralAstNodeType? typeLiteralAstNodeType = this._getTypeLiteralAstNodeType(element);
		return typeLiteralAstNodeType?.arrGenericNodes[1].getFullName() ?? "String";
	}

	TypeLiteralAstNodeType? _getTypeLiteralAstNodeType(FieldElement element) {
		DartType type = element.type;
		String typeLiteral = type.getDisplayString(withNullability: true);
		TypeLiteralAstNodeType typeLiteralAstNodeType = this._svcTypeLiteralParser.parseTypeLiteral(typeLiteral);
		if (!typeLiteralAstNodeType.isMap()) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Expected a Map type, but got: ${typeLiteralAstNodeType.getFullName()}");
			return null;
		}

		if (typeLiteralAstNodeType.arrGenericNodes.length != 2) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Expected a Map with two generic types, but got: ${typeLiteralAstNodeType.getFullName()}");
			return null;
		}

		if (typeLiteralAstNodeType.arrGenericNodes[0].isNullable || typeLiteralAstNodeType.arrGenericNodes[1].isNullable) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Expected a Map with two generic non-nullable types, but got: ${typeLiteralAstNodeType.getFullName()}");
			return null;
		}

		return typeLiteralAstNodeType;
	}

	@override
	EzRefs? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzRefs(name!);
	}
}