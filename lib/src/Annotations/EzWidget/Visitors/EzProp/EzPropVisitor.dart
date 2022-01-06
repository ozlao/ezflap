
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:ezflap/src/Annotations/EzWidget/EzProp/EzProp.dart';
import 'package:ezflap/src/Annotations/EzWidget/Visitors/FieldElementVisitorBase/FieldElementVisitorBase.dart';
import 'package:ezflap/src/Utils/ExtensionMethods/ExtensionMethods.dart';

class EzPropData extends EzFieldDataBase {
	@override
	String toString() {
		return "EzPropData: ${assignedName} (${typeWithNullability})";
	}
}

class EzPropVisitor extends FieldElementVisitorBase<EzProp, EzPropData> {
	@override
	// ignore: avoid_renaming_method_parameters
	EzPropData? makeData(EzProp ezProp, FieldElement element, DartObject objValue, ElementAnnotation elementAnnotation) {
		String derivedName = this.getDerivedName(element);
		String type = this.getType(element);
		String? defaultValueLiteral = this.getDefaultValueLiteral(element);
		bool isLate = this.getIsLate(element);
		bool isNullable = this.getIsNullable(element);
		bool isList = this.getIsList(element);

		return EzPropData()
			..assignedName = ezProp.name
			..derivedName = derivedName
			..typeWithNullability = type
			..defaultValueLiteral = defaultValueLiteral
			..isLate = isLate
			..isNullable = isNullable
			..isList = isList
		;
	}

	@override
	EzProp makeAnnotationClassInstance(String? name, DartObject objValue, ElementAnnotation elementAnnotation) {
		return EzProp(name!);
	}

	Map<String, EzPropData> getEzPropDataMap() {
		return this.getEzAnnotationData().toMap(
			funcKey: (item) => item.assignedName,
			funcValue: (item) => item,
		);
	}

	EzPropData? tryGetEzPropData(String assignedName) {
		return this.getEzAnnotationData().firstOrNull((x) => x.assignedName == assignedName);
	}
}