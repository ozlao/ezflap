
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzEmit/EzEmit.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';

class EzEmitData extends EzFieldDataBase {
	late final String functionParenthesesPart;
	
	@override
	String toString() {
		return "EzEmitData: ${assignedName} (${typeWithNullability})";
	}
}

class EzEmitVisitor extends FieldElementVisitorBase<EzEmit, EzEmitData> {
	static const String _COMPONENT = "EzEmitVisitor";

	EzEmitData? makeData(EzEmit ezField, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String type = this.getType(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		String functionParenthesesPart = this._getFunctionParenthesesPart(type);
		bool isList = this.getIsList(element);

		return EzEmitData()
			..assignedName = ezField.name
			..derivedName = derivedName
			..typeWithNullability = type
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..functionParenthesesPart = functionParenthesesPart
			..isList = isList
		;
	}

	@override
	EzEmit? makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzEmit(name!);
	}

	String _getFunctionParenthesesPart(String all) {
		int pos = all.indexOf("(");
		if (pos == -1) {
			this.svcLogger.logErrorFrom(_COMPONENT, "Could not find parentheses in function [${all}]");
			return "";
		}

		return all.substring(pos);
	}
}