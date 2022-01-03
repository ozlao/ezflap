
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzRef/EzRef.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';

class EzRefData extends EzFieldDataBase {
	@override
	String toString() {
		return "EzRefData: ${assignedName} (${typeWithNullability})";
	}
}

class EzRefVisitor extends FieldElementVisitorBase<EzRef, EzRefData> {
	@override
	EzRefData? makeData(EzRef ezRef, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String typeWithNullability = this.getType(element);
		String typeWithoutNullability = this.getTypeWithoutNullability(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		bool isList = this.getIsList(element);

		return EzRefData()
			..assignedName = ezRef.name
			..derivedName = derivedName
			..typeWithNullability = typeWithNullability
			..typeWithoutNullability = typeWithoutNullability
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..isList = isList
		;
	}

	@override
	EzRef makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzRef(name!);
	}
}