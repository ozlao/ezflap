
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzField/EzField.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';

class EzFieldData extends EzFieldDataBase {
	@override
	String toString() {
		return "EzFieldData: ${assignedName} (${typeWithNullability})";
	}
}

class EzFieldVisitor extends FieldElementVisitorBase<EzField, EzFieldData> {
	@override
	EzFieldData? makeData(EzField ezField, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String type = this.getType(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		bool isList = this.getIsList(element);

		return EzFieldData()
			..assignedName = ezField.name
			..derivedName = derivedName
			..typeWithNullability = type
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..isList = isList
		;
	}

	@override
	EzField makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzField(name!);
	}
}